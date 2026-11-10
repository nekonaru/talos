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
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Bridge between Flutter and the embedded Python runtime.
 *
 * All Python calls run on background threads. The Python side buffers raw
 * yt-dlp lines per task; a pump thread polls `drain` and forwards the lines
 * to Flutter over the event channel. No Java object is ever passed into
 * Python, so JNI/proxy attribute lookups cannot fail. The Dart side parses
 * the lines with the same parser used for desktop subprocesses.
 */
class TalosEngineBridge(private val application: Application) {
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

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
                    if (url.isNullOrEmpty()) {
                        result.error("bad_args", "A url is required", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val output = try {
                            ensureStarted()
                            Python.getInstance().getModule("talos_engine").callAttr("probe", url, proxy)?.toString()
                        } catch (e: Exception) {
                            android.util.Log.e("TalosEngine", "probe failed")
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
                    val argvJson = JSONArray(args).toString()
                    val finished = AtomicBoolean(false)
                    val outcome = AtomicReference<Map<String, Any?>>(null)
                    Thread {
                        try {
                            ensureStarted()
                            Python.getInstance().getModule("talos_engine").callAttr("init", taskId)
                            val raw = Python.getInstance().getModule("talos_engine")
                                .callAttr("run", taskId, argvJson)?.toString()
                            outcome.set(parseStatus(raw))
                        } catch (e: Exception) {
                            outcome.set(
                                mapOf(
                                    "event" to "error",
                                    "message" to (e.message ?: "Engine crashed"),
                                ),
                            )
                        } finally {
                            finished.set(true)
                        }
                    }.start()
                    Thread {
                        while (true) {
                            drainAndEmit(taskId)
                            if (finished.get()) {
                                drainAndEmit(taskId)
                                val final = outcome.get() ?: mapOf(
                                    "event" to "error",
                                    "message" to "Engine crashed",
                                )
                                sendEvent(taskId, final + ("taskId" to taskId))
                                try {
                                    Python.getInstance().getModule("talos_engine").callAttr("cleanup", taskId)
                                } catch (_: Exception) {
                                    // The Python interpreter may be gone; nothing to clean up.
                                }
                                break
                            }
                            Thread.sleep(60)
                        }
                    }.start()
                    result.success(true)
                }
                "cancel" -> {
                    val taskId = call.argument<String>("taskId")
                    if (!taskId.isNullOrEmpty()) {
                        Thread {
                            try {
                                ensureStarted()
                                Python.getInstance().getModule("talos_engine").callAttr("cancel", taskId)
                            } catch (_: Exception) {
                                // Nothing to cancel; the task either never started or is already done.
                            }
                        }.start()
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

    private fun drainAndEmit(taskId: String) {
        val json = try {
            Python.getInstance().getModule("talos_engine").callAttr("drain", taskId)?.toString() ?: "[]"
        } catch (_: Exception) {
            return
        }
        try {
            val items = JSONArray(json)
            for (i in 0 until items.length()) {
                val item = items.optJSONArray(i) ?: continue
                when (item.optString(0)) {
                    "line" -> sendEvent(
                        taskId,
                        mapOf("taskId" to taskId, "event" to "line", "line" to item.optString(1)),
                    )
                }
            }
        } catch (_: Exception) {
            // Malformed buffer payload; drop it, yt-dlp keeps running.
        }
    }

    private fun parseStatus(raw: String?): Map<String, Any?> {
        if (raw.isNullOrEmpty()) {
            return mapOf("event" to "error", "message" to "Engine returned no result")
        }
        return try {
            val obj = JSONObject(raw)
            when (obj.optString("status")) {
                "done" -> mapOf("event" to "done")
                "cancelled" -> mapOf("event" to "cancelled")
                else -> mapOf(
                    "event" to "error",
                    "message" to obj.optString("message", "Download failed"),
                )
            }
        } catch (_: Exception) {
            mapOf("event" to "error", "message" to "Engine returned an invalid result")
        }
    }

    private fun sendEvent(taskId: String, event: Map<String, Any?>) {
        val full = if (event.containsKey("taskId")) event else event + ("taskId" to taskId)
        mainHandler.post { eventSink?.success(full) }
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
