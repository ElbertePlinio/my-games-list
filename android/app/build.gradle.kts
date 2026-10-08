import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Upload/distribution signing credentials are kept out of the repo (see
// SIGNING.md). When `android/key.properties` is absent (CI without secrets, a
// fresh checkout), release falls back to debug signing so local builds keep
// working — the absence is handled gracefully, never a hard failure.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    // A present-but-incomplete file is a configuration mistake, not a reason to
    // silently fall back to debug signing — fail loudly with a clear message.
    val missing = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException(
            "android/key.properties is missing required keys: $missing. See SIGNING.md.",
        )
    }
}

android {
    namespace = "app.picklog"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "app.picklog"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Fallback name for flavorless builds (e.g. `flutter run` without
        // `--flavor`); each flavor overrides this below.
        resValue("string", "app_name", "Picklog")
    }

    flavorDimensions += "env"
    productFlavors {
        // Staging gets a distinct application id so it can be installed
        // side-by-side with production and mapped to the staging Firebase
        // project. The Dart environment is still selected via
        // `--dart-define=ENVIRONMENT=staging`; flavors only shape the Android
        // artifact (app id + name), they don't replace the dart-define flow.
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Picklog (Staging)")
        }
        create("prod") {
            dimension = "env"
            // No suffix: production keeps the base application id that the
            // production Firebase project / google-services.json is keyed to.
            resValue("string", "app_name", "Picklog")
        }
    }

    signingConfigs {
        // Only materialize the release config when the keystore is configured.
        // Reading a missing property here would crash configuration, so this
        // block is skipped entirely on machines without `key.properties`.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sign release artifacts with the real upload key when it is
            // present; otherwise fall back to the debug key so `flutter build`
            // / `flutter run --release` still work without secrets. See #14.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 is enabled by default for Flutter release builds; declaring it
            // explicitly documents intent and wires the custom keep rules that
            // stop the shrinker from stripping Firebase/Flutter symbols.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
