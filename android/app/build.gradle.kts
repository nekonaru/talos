import java.util.Properties

plugins {
    id("com.android.application")
    id("com.chaquo.python")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // The artifact only ships arm64-v8a and x86_64; x86_64 is excluded by the
    // abiFilters below in release builds. LGPL-3.0, dynamically linked.
    implementation("dev.ffmpegkit-maintained:ffmpeg-kit-min:8.1.9")
    implementation("androidx.documentfile:documentfile:1.0.1")
}

android {
    namespace = "id.nekonaru.talos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val keystorePropertiesFile = rootProject.file("app/key.properties")
    val keystoreProperties = Properties()
    val hasKeystore = try {
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
            keystoreProperties.getProperty("storeFile") != null
        } else {
            false
        }
    } catch (e: Exception) {
        false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.nekonaru.talos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Python 3.14 is 64-bit only. Ship arm64-v8a to cover most devices with a smaller APK.
        // Chaquopy requires abiFilters here for every build variant.
        ndk {
            abiFilters.addAll(listOf("arm64-v8a"))
        }
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // minSdk 24 and targetSdk 36 make APK Signature Scheme v2 the
                // correct choice. CI verifies the signature and ABI contents.
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Drop unused plugin resources and Dart symbols. Keep rules above
            // protect the reflection-based native bridges.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Never silently ship a release-looking APK signed with the debug
            // key. Fail early with an actionable message instead.
            if (!hasKeystore) error("Release signing key is missing: app/key.properties")
            signingConfig = signingConfigs.getByName("release")
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

chaquopy {
    defaultConfig {
        version = "3.14"
        pip {
            install("yt-dlp==2026.10.26")
        }
    }
}
