# Mantieni l embedding Flutter e il registrant dei plugin
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Mantieni TUTTI i plugin sotto io.flutter.plugins (AAR-based)
-keep class io.flutter.plugins.** { *; }

# Mantieni le classi del core di TacUNS (inclusi i tuoi canali)
-keep class com.sentinel.** { *; }

# CRITICO: mantieni i metodi della MainActivity che registrano i canali.
# R8 rimuove le lambda di setMethodCallHandler/setStreamHandler se non protette.
-keepclassmembers class com.sentinel.ui.MainActivity {
    *;
}

# Mantieni i membri dei MethodChannel/EventChannel handler
-keepclassmembers class ** {
    @io.flutter.embedding.engine.plugins.FlutterPlugin *;
}

# Gson (se usato)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Room
-keep class androidx.room.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Sopprimi warning Play Core (deferred components non usati)
-dontwarn com.google.android.play.core.**
