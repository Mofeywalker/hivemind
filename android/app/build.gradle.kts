import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties").takeIf { it.exists() }
    ?: project.file("key.properties").takeIf { it.exists() }
if (keystorePropertiesFile != null) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "de.mf1337.hivemind"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.mf1337.hivemind"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyPath = System.getenv("ANDROID_KEYSTORE_PATH")
                ?: keystoreProperties.getProperty("storeFile")
            val keyPasswordVal = System.getenv("ANDROID_KEY_PASSWORD")
                ?: keystoreProperties.getProperty("keyPassword")
            val keyAliasVal = System.getenv("ANDROID_KEY_ALIAS")
                ?: keystoreProperties.getProperty("keyAlias")
            val storePasswordVal = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                ?: keystoreProperties.getProperty("storePassword")

            val resolvedFile = when {
                keyPath.isNullOrBlank() -> null
                file(keyPath).exists() -> file(keyPath)
                rootProject.file(keyPath).exists() -> rootProject.file(keyPath)
                else -> null
            }

            if (resolvedFile != null) {
                storeFile = resolvedFile
                storePassword = storePasswordVal
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            when {
                releaseSigning.storeFile != null -> signingConfig = releaseSigning
                System.getenv("HIVEMIND_ALLOW_DEBUG_SIGNING") == "true" -> {
                    logger.warn(
                        "WARNING: building a release variant signed with the DEBUG key. " +
                            "This artifact is not publishable. " +
                            "Provide ANDROID_KEYSTORE_PATH / key.properties to sign properly."
                    )
                    signingConfig = signingConfigs.getByName("debug")
                }
                else -> throw GradleException(
                    "No release keystore configured. Provide ANDROID_KEYSTORE_PATH / " +
                        "key.properties, or set HIVEMIND_ALLOW_DEBUG_SIGNING=true to " +
                        "build an explicitly debug-signed release."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

