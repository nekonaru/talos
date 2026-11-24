# Flutter engine and plugin bridges are reached from generated code and native
# callbacks, so keep them intact.
-keep class io.flutter.** { *; }
-keep class id.nekonaru.talos.** { *; }
-keep class com.chaquo.python.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class androidx.documentfile.provider.** { *; }

# Method/Event channel handlers are instantiated reflectively by the engine.
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Foreground task callback is invoked from a separate isolate by name.
-keep class * extends com.pravera.flutter_foreground_task.service.ForegroundServiceTaskHandler { *; }

# Flutter's deferred-component support references Play Core, which is not a
# dependency of this app and is never used.
-dontwarn com.google.android.play.core.**

# Keep annotations and native method names used by JNI.
-keepattributes *Annotation*
-keepclasseswithmembernames class * {
    native <methods>;
}
