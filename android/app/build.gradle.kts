import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingProperties.load(FileInputStream(signingFile))
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
val configureFirebase = firebaseResources.keys.any { !dartDefines[it].isNullOrBlank() }
if (configureFirebase) {
    require(firebaseResources.keys.all { !dartDefines[it].isNullOrBlank() }) {
        "Supply all four Firebase client values in your --dart-define-from-file configuration."
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
        // Native FCM needs these public options before Dart starts in a cold process.
        if (configureFirebase) {
            firebaseResources.forEach { (define, resource) ->
                resValue("string", resource, dartDefines.getValue(define))
            }
        }
    }
    signingConfigs {
        create("release") {
            if (signingFile.exists()) {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release") }
    }
}
flutter { source = "../.." }
