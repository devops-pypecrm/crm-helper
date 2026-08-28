import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: loads android/key.properties if present (see
// key.properties.example for the template — the real file is gitignored
// and must be generated locally/by CI, never committed). Falls back to
// null (handled below by signing release builds with the debug key
// instead) so `flutter build apk`/`flutter run --release` still work for
// local development without a real keystore configured.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigningConfig = keystorePropertiesFile.exists()
if (hasReleaseSigningConfig) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.pypecrm.recorder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.pypecrm.recorder"
        // Matches packages/call_recording_engine's minSdk (a plugin's minSdk
        // must be <= the app's, and the Tier 0/Tier 4 native APIs used here
        // — MediaStore, CallLog, WorkManager — are all fine from API 24 up).
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Real release signing once android/key.properties exists (see
            // key.properties.example) — until then, falls back to the debug
            // key so `flutter build apk --release` still works locally.
            // This app CANNOT be distributed to real users while signed
            // with the debug key — Android will refuse to install an
            // update signed differently later, so switch this over before
            // the first real release, not after.
            signingConfig = if (hasReleaseSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 minification is OFF deliberately — this app isn't
            // Play-distributed, so APK-size trimming isn't worth the risk.
            // Confirmed the hard way: AGP 9's default (minifyEnabled=true
            // when unset) was stripping something androidx.work's internal
            // Room `WorkDatabase` needs at runtime, crashing the app before
            // Flutter even starts ("Failed to create an instance of class
            // androidx.work.impl.WorkDatabase", visible only on a real
            // device — release-mode-only, R8-only, so nothing in this
            // repo's compile-only verification could have caught it).
            isMinifyEnabled = false
            isShrinkResources = false
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
