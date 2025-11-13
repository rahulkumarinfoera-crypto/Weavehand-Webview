# Flutter's native connections
-keep class io.flutter.embedding.engine.FlutterJNI { *; }

# Google Sign-In and GMS tasks
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep interface com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep interface com.google.android.gms.tasks.** { *; }