import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — loaded from android/key.properties (gitignored). On CI the
// workflow writes this file from repo secrets. When absent (e.g. a plain local
// debug machine) we fall back to debug signing so the build still works.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.holyshrine.speech_translator_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Target JVM 17 bytecode using whichever JDK runs Gradle (JDK 21 here),
    // instead of requiring a separately-installed JDK 17 toolchain.
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.holyshrine.speech_translator_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Enable R8 for debug to test optimization effectiveness
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        release {
            // Stable upload key when key.properties exists; debug otherwise.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // App Bundle optimization configuration
    bundle {
        language {
            enableSplit = false  // Include all languages in each split
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    // NOTE: previously stripped several Agora native extensions
    // (clear_vision/lip_sync/segmentation/spatial_audio/ffmpeg .so) to shrink the
    // APK on the assumption they're never used by voice-only calls. That is a
    // native-crash risk: if the SDK dlopen()s a stripped lib during
    // initialize()/joinChannel(), the app hard-crashes to the home screen — the
    // observed "call answered → whole app closes" on mobile. Ship all bundled
    // Agora libs; re-introduce excludes only if proven safe via a crash log.
}

flutter {
    source = "../.."
}