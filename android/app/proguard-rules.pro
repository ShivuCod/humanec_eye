# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_face_detection.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Suppress TensorFlow GPU delegate warnings
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options 