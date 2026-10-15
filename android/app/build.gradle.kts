import java.util.Properties
import java.io.FileInputStream
import java.util.Base64
import java.net.URI

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingProperties.load(FileInputStream(signingFile))
mapOf("storeFile" to "ANDROID_KEYSTORE_PATH", "storePassword" to "ANDROID_KEYSTORE_PASSWORD",
    "keyAlias" to "ANDROID_KEY_ALIAS", "keyPassword" to "ANDROID_KEY_PASSWORD").forEach { (key, env) ->
    System.getenv(env)?.takeIf { it.isNotBlank() }?.let { signingProperties[key] = it }
}
val dartDefines = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.filter { it.isNotBlank() }?.associate {
        val entry = String(Base64.getDecoder().decode(it), Charsets.UTF_8).split("=", limit = 2)
        entry[0] to entry.getOrElse(1) { "" }
    } ?: emptyMap()
val firebaseResources = mapOf(
    "FIREBASE_APP_ID" to "google_app_id",
    "FIREBASE_API_KEY" to "google_api_key",
    "FIREBASE_MESSAGING_SENDER_ID" to "gcm_defaultSenderId",
    "FIREBASE_PROJECT_ID" to "project_id"
)
val pushEnabled = dartDefines["PUSH_NOTIFICATIONS_ENABLED"] != "false"
val configureFirebase = pushEnabled && firebaseResources.keys.any { !dartDefines[it].isNullOrBlank() }
if (configureFirebase) {
    require(firebaseResources.keys.all { !dartDefines[it].isNullOrBlank() }) {
        "Supply all four Firebase client values in your --dart-define-from-file configuration."
    }
}
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (releaseRequested) {
    require(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { signingProperties[it] != null }) {
        "Release signing is required. Configure private signing environment variables or android/key.properties."
    }
    if (dartDefines["APP_ENV"] != "development") {
        val api = URI(dartDefines["API_BASE_URL"] ?: "")
        require(api.scheme == "https" && !api.host.isNullOrBlank()) { "Release requires a public HTTPS API_BASE_URL." }
        require(configureFirebase || !pushEnabled || dartDefines["VALIDATION_ONLY"] == "true") {
            "Supply Firebase client values for push, or explicitly set PUSH_NOTIFICATIONS_ENABLED=false for a study-only beta."
        }
    }
}
android {
    namespace = "com.example.ankidsa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "app.ankidsa.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLinkHost"] = URI(dartDefines["APP_PUBLIC_URL"] ?: "https://unconfigured.invalid").host ?: "unconfigured.invalid"
        // Native FCM needs these public options before Dart starts in a cold process.
        if (configureFirebase) {
            firebaseResources.forEach { (define, resource) ->
                resValue("string", resource, dartDefines.getValue(define))
            }
        }
    }
    signingConfigs {
        create("release") {
            if (signingProperties["storeFile"] != null) {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
flutter { source = "../.." }
