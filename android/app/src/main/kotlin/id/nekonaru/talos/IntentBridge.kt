package id.nekonaru.talos

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Forwards links shared from other apps (text/plain) to Flutter, both at
 * cold start and while the activity is running.
 */
class IntentBridge {
    private var eventSink: EventChannel.EventSink? = null

    fun attach(flutterEngine: FlutterEngine, initialIntent: Intent?) {
        var pendingUrl = extractShareUrl(initialIntent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.nekonaru.talos/intent")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialPendingUrl" -> {
                        result.success(pendingUrl)
                        pendingUrl = null
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "id.nekonaru.talos/intent/share")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    fun onNewIntent(intent: Intent?) {
        val url = extractShareUrl(intent) ?: return
        eventSink?.success(url)
    }

    private fun extractShareUrl(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim() ?: return null
        val match = Regex("https?://\\S+").find(text)?.value
        if (match != null) return match
        return if (text.startsWith("http://") || text.startsWith("https://")) text else null
    }
}
