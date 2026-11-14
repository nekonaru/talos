package id.nekonaru.talos

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.os.Build
import android.provider.MediaStore
import android.content.ContentValues
import android.content.ContentResolver
import android.os.Environment
import android.Manifest
import android.content.pm.PackageManager
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Bridge to Android's Storage Access Framework so users can pick any
 * writable folder (for example the public Downloads folder) and Talos
 * writes downloads into a "Talos" child directory inside the picked tree,
 * so the user can pick the public Downloads folder and get
 * Downloads/Talos/<file>. If the picked folder is itself already named
 * Talos, downloads are written directly into it.
 *
 * Method channels:
 * - "pickTree"    opens the system folder picker; persists READ+WRITE URI
 *                 grant; returns the URI string (null when cancelled).
 * - "clearTree"   forgets the persisted tree; downloads fall back to
 *                 the public Downloads folder (or private storage).
 * - "getTreeUri"  returns the currently persisted URI string ("" when unset).
 * - "copyToTree"  copies a local file into the picked tree; never overwrites,
 *                 a " (N)"-style unique name is chosen; returns the new
 *                 content URI ("" on failure).
 * - "saveToDownloads"
 *                 writes a local file into the public Downloads/Talos folder.
 *                 API 29+: MediaStore insert, no permission needed.
 *                 API 24-28: direct path write, needs WRITE_EXTERNAL_STORAGE
 *                 (requested on first launch). Never overwrites; a unique
 *                 "name(N).ext" is chosen. Returns true on success.
 * - "requestFirstLaunchPermissions"
 *                 asks for POST_NOTIFICATIONS (API 33+) and
 *                 WRITE_EXTERNAL_STORAGE (API 24-28) exactly once per install.
 * - "androidSdkInt" returns the platform SDK integer.
 * - "deleteInTree" deletes a file by display name from the picked tree.
 * - "deleteUri"   deletes a document by its full URI (O(1)).
 */
class TalosStorageBridge(private val context: Context) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var treeUriString: String? = null
    private var hostActivity: Activity? = null

    companion object {
        const val CHANNEL = "id.nekonaru.talos/storage"
        const val PICK_TREE = 9001
        const val REQUEST_FIRST_LAUNCH = 9002
        private const val PREFS = "talos_storage_prefs"
        private const val KEY_TREE = "treeUri"
        private const val KEY_PROMPTED = "permissionsPrompted"

        private fun mimeFor(fileName: String): String {
            val lower = fileName.lowercase()
            return when {
                lower.endsWith(".mp4") || lower.endsWith(".m4a") || lower.endsWith(".3gp") -> "video/mp4"
                lower.endsWith(".mkv") -> "video/x-matroska"
                lower.endsWith(".webm") -> "video/webm"
                lower.endsWith(".mp3") -> "audio/mpeg"
                lower.endsWith(".flac") -> "audio/flac"
                lower.endsWith(".opus") -> "audio/opus"
                lower.endsWith(".ogg") -> "audio/ogg"
                lower.endsWith(".mka") -> "audio/x-matroska"
                lower.endsWith(".aac") -> "audio/aac"
                else -> "application/octet-stream"
            }
        }
    }

    fun attach(flutterEngine: FlutterEngine, activity: Activity) {
        hostActivity = activity
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        treeUriString = prefs.getString(KEY_TREE, null)
        if (treeUriString != null) {
            val tree = DocumentFile.fromTreeUri(context, Uri.parse(treeUriString))
            if (tree == null || !tree.isDirectory || !tree.exists()) {
                treeUriString = null
                prefs.edit().remove(KEY_TREE).apply()
            }
        }
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickTree" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                        )
                    }
                    activity.startActivityForResult(intent, PICK_TREE)
                }
                "clearTree" -> {
                    treeUriString = null
                    prefs.edit().remove(KEY_TREE).apply()
                    result.success(null)
                }
                "getTreeUri" -> result.success(treeUriString ?: "")
                "copyToTree" -> {
                    val localPath = call.argument<String>("localPath") ?: ""
                    val displayName = call.argument<String>("displayName") ?: ""
                    result.success(copyToTree(localPath, displayName))
                }
                "saveToDownloads" -> {
                    val localPath = call.argument<String>("localPath") ?: ""
                    val displayName = call.argument<String>("displayName") ?: ""
                    result.success(saveToDownloads(localPath, displayName))
                }
                "requestFirstLaunchPermissions" -> result.success(requestFirstLaunchPermissions())
                "androidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "openUri" -> {
                    val uriString = call.argument<String>("uri") ?: ""
                    result.success(openUri(uriString))
                }
                "shareUri" -> {
                    val uriString = call.argument<String>("uri") ?: ""
                    result.success(shareUri(uriString))
                }
                "deleteInTree" -> {
                    val displayName = call.argument<String>("displayName") ?: ""
                    result.success(deleteInTree(displayName))
                }
                "deleteUri" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    result.success(deleteUri(Uri.parse(uri)))
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Persist the URI grant and store it for future use. */
    fun onPickedTree(treeUri: Uri?) {
        mainHandler.post {
            pendingResult?.success(treeUri?.toString())
            pendingResult = null
        }
        if (treeUri == null) return
        try {
            context.contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // The picker already granted persistable access for the returned URI.
        }
        treeUriString = treeUri.toString()
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_TREE, treeUriString)
            .apply()
    }

    private fun talosDir(tree: DocumentFile): DocumentFile? {
        if (tree.name.equals("Talos", ignoreCase = true)) return tree
        return try {
            tree.findFile("Talos") ?: tree.createDirectory("Talos")
        } catch (_: Exception) {
            null
        }
    }

    /** Open a content or file URI with the app's default handler. */
    private fun openUri(uriString: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val mime = context.contentResolver.getType(uri) ?: "*/*"
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val target = hostActivity
            if (target != null) {
                target.startActivity(intent)
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Share a content or file URI through the Android share sheet. */
    private fun shareUri(uriString: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val mime = context.contentResolver.getType(uri) ?: "*/*"
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mime
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(intent, null)
            val target = hostActivity
            if (target != null) {
                target.startActivity(chooser)
            } else {
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(chooser)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Pick a unique sibling name that does not collide in the tree. */
    private fun uniqueTreeFileName(target: DocumentFile, displayName: String): String {
        if (target.findFile(displayName) == null) return displayName
        val dot = displayName.lastIndexOf('.')
        val base = if (dot >= 0) displayName.substring(0, dot) else displayName
        val ext = if (dot >= 0) displayName.substring(dot) else ""
        for (i in 1..9999) {
            val candidate = "$base($i)$ext"
            if (target.findFile(candidate) == null) return candidate
        }
        return displayName
    }

    private fun copyToTree(localPath: String, displayName: String): String? {
        val tree = treeUriString?.let { Uri.parse(it) }?.let { DocumentFile.fromTreeUri(context, it) } ?: return null
        val target = talosDir(tree) ?: return null
        if (!target.canWrite()) return null
        val uniqueName = uniqueTreeFileName(target, displayName)
        val created = target.createFile(
            mimeFor(uniqueName),
            uniqueName.substringBeforeLast('.', uniqueName),
        ) ?: return null
        val source = File(localPath)
        if (!source.exists()) return null
        source.inputStream().use { input ->
            context.contentResolver.openOutputStream(created.uri)?.use { output ->
                input.copyTo(output)
            } ?: return null
        }
        return created.uri.toString()
    }

    /**
     * Write a local file into the public Downloads/Talos folder.
     *
     * API 29+ uses a MediaStore insert into the Downloads collection, so no
     * storage permission is needed at all. API 24-28 falls back to a direct
     * file write into /storage/emulated/0/Download/Talos, which requires
     * WRITE_EXTERNAL_STORAGE (covered by the first-launch prompt). Never
     * overwrites; a "name(N).ext" sibling is chosen when the name exists.
     */
    private fun saveToDownloads(localPath: String, displayName: String): String? {
        val file = File(localPath)
        if (!file.exists()) return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveViaMediaStore(file, displayName)
        } else {
            saveViaLegacyPath(file, displayName)?.let { target -> "file://${target.absolutePath}" }
        }
    }

    private fun saveViaLegacyPath(file: File, displayName: String): File? {
        return try {
            val dir = File(File(Environment.getExternalStorageDirectory(), "Download"), "Talos")
            if (!dir.exists() && !dir.mkdirs()) return null
            val dot = displayName.lastIndexOf('.')
            val base = if (dot >= 0) displayName.substring(0, dot) else displayName
            val ext = if (dot >= 0) displayName.substring(dot) else ""
            var target = File(dir, displayName)
            var i = 1
            while (target.exists() && i < 10000) {
                target = File(dir, "$base($i)$ext")
                i++
            }
            file.inputStream().use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            target
        } catch (_: Exception) {
            null
        }
    }

    private fun saveViaMediaStore(file: File, displayName: String): String? {
        val resolver = context.contentResolver
        val name = uniqueMediaStoreName(resolver, displayName)
        val values = ContentValues().apply {
            put(MediaStore.Downloads.RELATIVE_PATH, "Download/Talos")
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mimeFor(name))
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = try {
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
        } catch (_: Exception) {
            null
        } ?: return null
        return try {
            resolver.openOutputStream(uri)?.use { output ->
                file.inputStream().use { input -> input.copyTo(output) }
            } ?: throw java.io.IOException("could not open output stream")
            val done = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
            uri.toString()
        } catch (_: Exception) {
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
                // Best effort cleanup.
            }
            null
        }
    }

    private fun uniqueMediaStoreName(resolver: ContentResolver, displayName: String): String {
        if (!mediaStoreNameExists(resolver, displayName)) return displayName
        val dot = displayName.lastIndexOf('.')
        val base = if (dot >= 0) displayName.substring(0, dot) else displayName
        val ext = if (dot >= 0) displayName.substring(dot) else ""
        for (i in 1..9999) {
            val candidate = "$base($i)$ext"
            if (!mediaStoreNameExists(resolver, candidate)) return candidate
        }
        return displayName
    }

    private fun mediaStoreNameExists(resolver: ContentResolver, displayName: String): Boolean {
        return try {
            resolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} LIKE ?",
                arrayOf(displayName, "Download/Talos%"),
                null,
            ).use { cursor -> cursor != null && cursor.count > 0 }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Ask for the runtime permissions Talos needs, exactly once per install.
     * POST_NOTIFICATIONS is needed on API 33+; WRITE_EXTERNAL_STORAGE is
     * needed on API 24-28 to write the public Downloads folder directly.
     * On API 29+ the public Downloads folder is reached through MediaStore
     * and needs no permission.
     */
    private fun requestFirstLaunchPermissions(): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(KEY_PROMPTED, false)) return "skipped"
        prefs.edit().putBoolean(KEY_PROMPTED, true).apply()
        val sdk = Build.VERSION.SDK_INT
        val needed = mutableListOf<String>()
        if (sdk >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            needed.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (sdk <= 28 && context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            needed.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        val activity = hostActivity
        if (needed.isNotEmpty() && activity != null) {
            mainHandler.post {
                try {
                    activity.requestPermissions(needed.toTypedArray(), REQUEST_FIRST_LAUNCH)
                } catch (_: Exception) {
                    // The system dialog is best effort; downloads keep working.
                }
            }
        }
        return "requested"
    }

    private fun deleteInTree(displayName: String): Boolean {
        val tree = treeUriString?.let { Uri.parse(it) }?.let { DocumentFile.fromTreeUri(context, it) } ?: return false
        val target = talosDir(tree) ?: return false
        val file = target.findFile(displayName) ?: return false
        return try {
            file.delete()
        } catch (_: Exception) {
            false
        }
    }

    private fun deleteUri(uri: Uri): Boolean {
        return try {
            DocumentsContract.deleteDocument(context.contentResolver, uri) ?: false
        } catch (_: Exception) {
            false
        }
    }
}
