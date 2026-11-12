package id.nekonaru.talos

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
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
 *                 app-private storage.
 * - "getTreeUri"  returns the currently persisted URI string ("" when unset).
 * - "copyToTree"  copies a local file into the picked tree; returns the new
 *                 content URI ("" on failure).
 * - "deleteInTree" deletes a file by display name from the picked tree.
 * - "deleteUri"   deletes a document by its full URI (O(1)).
 */
class TalosStorageBridge(private val context: Context) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var treeUriString: String? = null

    companion object {
        private const val CHANNEL = "id.nekonaru.talos/storage"
        private const val PREFS = "talos_storage_prefs"
        private const val KEY_TREE = "treeUri"
        private const val PICK_TREE = 9001

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
    fun onPickedTree(treeUri: Uri) {
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
        mainHandler.post {
            pendingResult?.success(treeUriString)
            pendingResult = null
        }
    }

    private fun talosDir(tree: DocumentFile): DocumentFile? {
        if (tree.name.equals("Talos", ignoreCase = true)) return tree
        return try {
            tree.findFile("Talos") ?: tree.createDirectory("Talos")
        } catch (_: Exception) {
            null
        }
    }

    private fun copyToTree(localPath: String, displayName: String): String? {
        val tree = treeUriString?.let { Uri.parse(it) }?.let { DocumentFile.fromTreeUri(context, it) } ?: return null
        val target = talosDir(tree) ?: return null
        if (!target.canWrite()) return null
        val created = target.findFile(displayName)
            ?: target.createFile(mimeFor(displayName), displayName.substringBeforeLast('.', displayName))
            ?: return null
        File(localPath).inputStream().use { input ->
            context.contentResolver.openOutputStream(created.uri)?.use { output ->
                input.copyTo(output)
            } ?: return null
        }
        return created.uri.toString()
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
