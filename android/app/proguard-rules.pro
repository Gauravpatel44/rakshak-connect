# =============================================================================
# ProGuard / R8 rules for Rakshak Connect (Flutter + Firebase)
# =============================================================================
# R8 is a code shrinker/obfuscator that:
#   - Removes unused classes -> smaller APK
#   - Renames classes/methods -> harder for static scanners to flag class names
#   - Removes dead code -> faster app startup
#
# Flutter's Dart code is compiled to native ARM/x64 and is NOT processed by R8.
# Only the Java/Kotlin layer (plugins, Firebase, platform channels) is affected.
# =============================================================================

# -- Flutter Engine -----------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# -- Firebase -----------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# -- Google Play Services / Maps ----------------------------------------------
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.android.** { *; }

# -- Home Widget --------------------------------------------------------------
-keep class es.antonborri.home_widget.** { *; }

# -- Geolocator ---------------------------------------------------------------
-keep class com.baseflow.geolocator.** { *; }

# -- Image Picker / Compress --------------------------------------------------
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.fluttercandies.** { *; }

# -- Audio Players ------------------------------------------------------------
-keep class xyz.luan.audioplayers.** { *; }

# -- Torch Light --------------------------------------------------------------
-keep class com.jitesh.torch_light.** { *; }

# -- Record (audio recorder) --------------------------------------------------
-keep class com.llfbandit.record.** { *; }

# -- Flutter Contacts ---------------------------------------------------------
-keep class com.jp.flutter_contacts.** { *; }

# -- Permission Handler -------------------------------------------------------
-keep class com.baseflow.permissionhandler.** { *; }

# -- URL Launcher -------------------------------------------------------------
-keep class io.flutter.plugins.urllauncher.** { *; }

# -- Path Provider ------------------------------------------------------------
-keep class io.flutter.plugins.pathprovider.** { *; }

# -- Shared Preferences -------------------------------------------------------
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# -- App Widget (native) ------------------------------------------------------
-keep class com.gaurav.rakshak_connect.** { *; }

# -- General Android safety ---------------------------------------------------
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.**
