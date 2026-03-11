# Keep Stripe and React Native Stripe classes used for push provisioning to avoid R8 missing-class errors
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Ignore missing Google Play Core classes referenced by Flutter deferred components
-dontwarn com.google.android.play.core.**

# General keep rules for Flutter (safe defaults)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

