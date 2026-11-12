package id.nekonaru.talos

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.InputStream
import java.io.OutputStream

/**
 * Bridge to Android's Storage Access Framework so the user can pick, list
 * and write into a folder of their choice (for example the public Downloads
 * folder) without MANAGE_EXTERNAL_STORAGE or per-path permissions.
 *
 * Layout of what Flutter sees:
 * - "pickTree"        launches ACTION_OPEN_DOCUMENT_TREE, persists a URI grant,
 *                     returns the URI string (null when cancelled).
 * - "clearTree"       drops the persisted grant from our record; the URI is
 *                     still trusted by the system but we forget it.
 * - "copyToTree"      copies a local file into the persisted tree; returns
 *                     the new display name on success.
 * - "deleteInTree"    looks up a child by display name and deletes it.
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
        val cached = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        treeUriString = cached.getString(KEY_TREE, null)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickTree" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    }
                    activity.startActivityForResult(intent, PICK_TREE)
                }
                "clearTree" -> {
                    treeUriString = null
                    cached.edit().remove(KEY_TREE).apply()
                    result.success(null)
                }
                "getTreeUri" -> result.success(treeUriString)
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
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } catch (_: SecurityException) {
            // Permission was already persisted when the picker returned the URI
            // with FLAG_GRANT_PERSISTABLE_URI_PERMISSION.
        }
        treeUriString = treeUri.toString()
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_TREE, treeUriString)
            .apply()
        mainHandler.post {
            pendingResult?.success(treeUriString)
            pendingResult = null
        }
    }

    private fun copyToTree(localPath: String, displayName: String): String? {
        val tree = treeUriString?.let { Uri.parse(it) }?.let { DocumentFile.fromTreeUri(context, it) } ?: return null
        if (!tree.canWrite()) return null
        val mime = mimeFor(displayName)
        val target = tree.findFile(displayName) ?: tree.createFile(mime, displayName.substringBeforeLast('.', displayName)) ?: return null
        File(localPath).inputStream().use { input ->
            context.contentResolver.openOutputStream(target.uri)?.use { output ->
                input.copyTo(output)
            } ?: return null
        }
        return target.uri.toString()
    }

    private fun deleteInTree(displayName: String): Boolean {
        val tree = treeUriString?.let { Uri.parse(it) }?.let { DocumentFile.fromTreeUri(context, it) } ?: return false
        if (!tree.canWrite()) return false
        val target = tree.findFile(displayName) ?: return false
        return try {
            target.delete()
        } catch (_: Exception) {
            false
        }
    }

    private fun deleteUri(uri: Uri): Boolean {
        return try {
            // Direct document deletion is O(1) and does not require finding the file by name.
            android.provider.DocumentsContract.deleteDocument(context.contentResolver, uri) ?: false
        } catch (_: Exception) {
            false
        }
    }
}
