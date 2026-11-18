import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    println(">>> [GRADLE SIGNING] Found key.properties at: ${keystorePropertiesFile.absolutePath}")
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
} else {
    println(">>> [GRADLE SIGNING] WARNING: key.properties NOT found at: ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "com.example.aris_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.aris_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val storePath = keystoreProperties["storeFile"] as String
                val targetFile = if (file(storePath).exists()) file(storePath) else rootProject.file(storePath)
                println(">>> [GRADLE SIGNING] Keystore file resolved to: ${targetFile.absolutePath} (exists: ${targetFile.exists()})")
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = targetFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                println(">>> [GRADLE SIGNING] Configuring release build with RELEASE signingConfig")
                signingConfig = signingConfigs.getByName("release")
            } else {
                println(">>> [GRADLE SIGNING] Configuring release build with DEBUG signingConfig")
                signingConfig = signingConfigs.getByName("debug")
            }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}