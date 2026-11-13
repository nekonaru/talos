package id.nekonaru.talos

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var bridge: TalosEngineBridge? = null
    private val intentBridge = IntentBridge()
    private val storageBridge by lazy { TalosStorageBridge(applicationContext) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val engine = TalosEngineBridge(application)
        bridge = engine
        engine.attach(flutterEngine)
        intentBridge.attach(flutterEngine, intent)
        storageBridge.attach(flutterEngine, this)
        // Warm the Python runtime on a background thread so the first probe
        // doesn't pay the cold start cost and the first frame is not blocked.
        Thread {
            try {
                engine.ensureStarted()
            } catch (_: Exception) {
            }
        }.start()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intentBridge.onNewIntent(intent)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != TalosStorageBridge.PICK_TREE) return
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            storageBridge.onPickedTree(uri)
        } else {
            // The user cancelled or the system refused the pick. Flutter is
            // waiting on pickDownloadsTree(); release it with null.
            storageBridge.onPickedTree(null)
        }
    }
}
