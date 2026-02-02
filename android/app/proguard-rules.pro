# Basic ProGuard rules for Flutter
# Keep Flutter classes and reflection used by plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Play Store Core classes (SplitInstall, DynamicDelivery)
-keep class com.google.android.play.core.** { *; }
-keepclassmembers class * {
    com.google.android.play.core.splitinstall.SplitInstall** *;
    com.google.android.play.core.splitcompat.** *;
    com.google.android.play.core.tasks.** *;
}

# Keep okhttp/async code used by some plugins
-dontwarn okhttp3.**
-dontwarn okio.**
