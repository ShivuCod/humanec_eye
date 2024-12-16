# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Suppress TensorFlow GPU delegate warnings
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options 