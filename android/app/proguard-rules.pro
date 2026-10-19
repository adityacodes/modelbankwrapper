# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }


# org.dpdns.mytpp.auth (MainActivity, InAppBrowserActivity)
-keep class org.dpdns.mytpp.auth.** { *; }
-keepclassmembers class org.dpdns.mytpp.auth.** { *; }

# Play Core (Flutter deferred components / split install)
-dontwarn com.google.android.play.core.**
