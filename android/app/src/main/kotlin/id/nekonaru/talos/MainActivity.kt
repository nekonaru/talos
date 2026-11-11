package id.nekonaru.talos

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var bridge: TalosEngineBridge? = null
    private val intentBridge = IntentBridge()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val engine = TalosEngineBridge(application)
        bridge = engine
        engine.attach(flutterEngine)
        intentBridge.attach(flutterEngine, intent)
        // Warm the Python runtime on a background thread so the first probe
        // does not pay the cold start cost and the first frame is not blocked.
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
}
