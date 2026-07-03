# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit (all text recognition variants)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Google Play Core (deferred components)
-keep class com.google.android.play.core.** { *; }

# Agora RTC engine (voice calls) — R8 must not strip the native SDK classes.
-keep class io.agora.**{*;}
-dontwarn io.agora.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Suppress R8 missing class warnings for optional dependencies
-dontwarn com.google.android.play.core.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
