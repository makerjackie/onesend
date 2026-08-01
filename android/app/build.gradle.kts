plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val oneSendReleaseStore = System.getenv("ONESEND_ANDROID_KEYSTORE_PATH")
val oneSendReleaseStorePassword =
    System.getenv("ONESEND_ANDROID_STORE_PASSWORD")
val oneSendReleaseKeyAlias = System.getenv("ONESEND_ANDROID_KEY_ALIAS")
val oneSendReleaseKeyPassword = System.getenv("ONESEND_ANDROID_KEY_PASSWORD")
val oneSendReleaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val oneSendReleaseConfigured = listOf(
    oneSendReleaseStore,
    oneSendReleaseStorePassword,
    oneSendReleaseKeyAlias,
    oneSendReleaseKeyPassword,
).all { !it.isNullOrBlank() }

if (oneSendReleaseRequested && !oneSendReleaseConfigured) {
    throw GradleException(
        "OneSend release signing is not configured. Refusing to create a debug-signed release artifact.",
    )
}

android {
    namespace = "com.makerjackie.onesend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.makerjackie.onesend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (oneSendReleaseConfigured) {
            create("release") {
                storeFile = file(oneSendReleaseStore!!)
                storePassword = oneSendReleaseStorePassword!!
                keyAlias = oneSendReleaseKeyAlias!!
                keyPassword = oneSendReleaseKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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
