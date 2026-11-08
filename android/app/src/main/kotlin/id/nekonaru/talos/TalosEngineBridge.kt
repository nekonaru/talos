package id.nekonaru.talos

import android.app.Application
import android.os.Handler
import android.os.Looper
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

/**
 * Bridge between Flutter and the embedded Python runtime.
 *
 * All Python calls run on background threads. Progress lines are forwarded
 * verbatim from yt-dlp and parsed on the Dart side with the same parser
 * used for desktop subprocesses.
 */
class TalosEngineBridge(private val application: Application) {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val bridges = mutableMapOf<String, EngineBridge>()
    private val lock = Object()

    fun attach(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val method = MethodChannel(messenger, "id.nekonaru.talos/engine")
        val events = EventChannel(messenger, "id.nekonaru.talos/engine/events")

        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        method.setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> {
                    ensureStartedCatching()
                    result.success(statusMap())
                }
                "setup" -> {
                    Thread {
                        ensureStartedCatching()
                        val ok = statusMap()["ready"] as? Boolean ?: false
                        mainHandler.post { result.success(ok) }
                    }.start()
                }
                "probe" -> {
                    val url = call.argument<String>("url")
                    val proxy = call.argument<String>("proxy") ?: ""
                    android.util.Log.d("TalosEngine", "probe requested")
                    if (url.isNullOrEmpty()) {
                        result.error("bad_args", "A url is required", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val output = try {
                            ensureStarted()
                            Python.getInstance().getModule("talos_engine").callAttr("probe", url, proxy)?.toString()
                        } catch (e: Exception) {
                            android.util.Log.e("TalosEngine", "probe failed", e)
                            null
                        }
                        mainHandler.post {
                            if (output != null && output.isNotEmpty()) {
                                result.success(output)
                            } else {
                                result.error("probe_failed", "Could not read media information", null)
                            }
                        }
                    }.start()
                }
                "start" -> {
                    val taskId = call.argument<String>("taskId")
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    if (taskId.isNullOrEmpty()) {
                        result.error("bad_args", "A taskId is required", null)
                        return@setMethodCallHandler
                    }
                    val bridge = EngineBridge(taskId) { id, event -> sendEvent(id, event) }
                    synchronized(lock) { bridges[taskId] = bridge }
                    Thread {
                        try {
                            ensureStarted()
                            val argvJson = JSONArray(args).toString()
                            Python.getInstance().getModule("talos_engine").callAttr("run", taskId, argvJson, bridge)
                        } catch (e: Exception) {
                            sendEvent(taskId, mapOf(
                                "taskId" to taskId,
                                "event" to "error",
                                "message" to (e.message ?: "Engine crashed"),
                            ))
                        } finally {
                            synchronized(lock) { bridges.remove(taskId) }
                        }
                    }.start()
                    result.success(true)
                }
                "cancel" -> {
                    val taskId = call.argument<String>("taskId")
                    if (!taskId.isNullOrEmpty()) {
                        synchronized(lock) { bridges[taskId]?.cancelled = true }
                    }
                    result.success(true)
                }
                "custom" -> {
                    val template = call.argument<String>("template") ?: ""
                    val url = call.argument<String>("url") ?: ""
                    Thread {
                        val output = try {
                            ensureStarted()
                            Python.getInstance().getModule("talos_engine").callAttr("custom", template, url)?.toString() ?: ""
                        } catch (e: Exception) {
                            "Command failed: ${e.message}"
                        }
                        mainHandler.post { result.success(output) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendEvent(taskId: String, event: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(event) }
    }

    private fun ensureStarted() {
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(application))
        }
    }

    private fun ensureStartedCatching() {
        try {
            ensureStarted()
        } catch (_: Exception) {
        }
    }

    private fun statusMap(): Map<String, Any?> {
        return try {
            ensureStarted()
            val version = Python.getInstance().getModule("talos_engine").callAttr("version")?.toString()
            mapOf("ready" to true, "version" to version, "managed" to true)
        } catch (e: Exception) {
            mapOf("ready" to false, "version" to null, "managed" to true)
        }
    }
}

class EngineBridge(val taskId: String, private val sink: (String, Map<String, Any?>) -> Unit) {
    @Volatile
    var cancelled: Boolean = false

    fun onLine(line: String) {
        sink(taskId, mapOf("taskId" to taskId, "event" to "line", "line" to line))
    }

    fun onDone() {
        sink(taskId, mapOf("taskId" to taskId, "event" to "done"))
    }

    fun onCancelled() {
        sink(taskId, mapOf("taskId" to taskId, "event" to "cancelled"))
    }

    fun onError(message: String) {
        sink(taskId, mapOf("taskId" to taskId, "event" to "error", "message" to message))
    }

    fun isCancelled(): Boolean = cancelled
}
