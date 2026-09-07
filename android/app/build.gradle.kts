import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release Signing ──────────────────────────────────────────────────────────
// key.properties and release.jks live in android/ directory.
// Both are gitignored — NEVER commit these files to version control.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.gaurav.rakshak_connect"
    compileSdk = 36
    ndkVersion = "28.2.13676358"
    buildToolsVersion = "36.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (uses Java 8+ time APIs)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.gaurav.rakshak_connect"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties.getProperty("keyAlias") ?: ""
            keyPassword = keyProperties.getProperty("keyPassword") ?: ""
            val sf = keyProperties.getProperty("storeFile")
            storeFile = if (!sf.isNullOrEmpty()) file(sf) else null
            storePassword = keyProperties.getProperty("storePassword") ?: ""
        }
    }

    buildTypes {
        release {
            // Sign with the release keystore loaded from key.properties
            signingConfig = signingConfigs.getByName("release")

            // ── R8 Code Shrinking ────────────────────────────────────────────
            // Reduces APK size ~30-40% and removes full class names visible to
            // static scanners. Required for Play Store release.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring — required by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
