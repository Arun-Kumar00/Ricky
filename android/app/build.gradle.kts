import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Function to get version name from pubspec.yaml
fun getVersionName(): String {
    val pubspecFile = rootProject.file("pubspec.yaml")
    if (pubspecFile.exists()) {
        val regex = Regex("version: (\\d+\\.\\d+\\.\\d+)\\+(\\d+)")
        val match = regex.find(pubspecFile.readText())
        if (match != null) {
            return match.groupValues[1]
        }
    }
    return "1.0.0"
}

// Function to get version code from pubspec.yaml
fun getVersionCode(): Int {
    val pubspecFile = rootProject.file("pubspec.yaml")
    if (pubspecFile.exists()) {
        val regex = Regex("version: (\\d+\\.\\d+\\.\\d+)\\+(\\d+)")
        val match = regex.find(pubspecFile.readText())
        if (match != null) {
            return match.groupValues[2].toInt()
        }
    }
    return 1
}

android {
    namespace = "com.arunnitd.ricky"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.arunnitd.ricky"
        minSdk = 24
        targetSdk = 35
        versionCode = 5
        versionName = "1.1.1"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
