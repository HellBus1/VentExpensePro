# ──────────────────────────────────────────────────────────────────────────────
# VentExpensePro — ProGuard / R8 Rules
# ──────────────────────────────────────────────────────────────────────────────

# ── Flutter Engine ────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase Crashlytics ─────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable        # Readable stack traces
-keep public class * extends java.lang.Exception  # Keep custom exceptions
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# ── Firebase Core ────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── Google Play Services / Auth ──────────────────────────────────────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Google Drive API & HTTP Client ───────────────────────────────────────────
-keep class com.google.api.client.** { *; }
-keep class com.google.api.services.drive.** { *; }
-keep class com.google.http.** { *; }
-dontwarn com.google.api.client.**
-dontwarn com.google.api.services.**
-dontwarn com.google.http.**

# ── Gson (used by Google HTTP Client) ────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ── SharedPreferences ────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**

# ── SQFlite (SQLite) ─────────────────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# ── Path Provider ────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── Share Plus ───────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ── PDF Generation ───────────────────────────────────────────────────────────
-keep class com.ril.pdf_box.** { *; }
-dontwarn com.ril.pdf_box.**

# ── Kotlin ───────────────────────────────────────────────────────────────────
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ── Kotlin Serialization ────────────────────────────────────────────────────
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# ── General ──────────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes EnclosingMethod

# Suppress warnings for common third-party libraries
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn org.apache.http.**
-dontwarn android.net.http.**
