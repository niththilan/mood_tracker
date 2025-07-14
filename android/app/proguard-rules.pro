# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Play Services
-keep class * extends java.util.ListResourceBundle {
    protected java.lang.Object[][] getContents();
}

# Keep Google Auth classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep for Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Retrofit/OkHttp (used by Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# Keep Flutter plugin classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase related classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**
