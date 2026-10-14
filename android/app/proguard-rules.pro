# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Play Core (Deferred Components)
-dontwarn com.google.android.play.core.**

# WorkManager & Room (Critical fix for "Failed to create an instance of androidx.work.impl.WorkDatabase")
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn androidx.work.**
-dontwarn androidx.startup.**
-dontwarn androidx.room.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# In-App Purchase
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**
