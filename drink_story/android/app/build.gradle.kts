// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ivarte.storystroll2"

    // Требуют плагины (mobile_scanner, path_provider_android и др.)
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ivarte.storystroll2"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        // Берём версию из pubspec.yaml
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // key.properties лежит в android/key.properties
            val keystoreFile = rootProject.file("key.properties")
            require(keystoreFile.exists()) { "key.properties not found at android/key.properties" }

            val p = Properties().apply { load(FileInputStream(keystoreFile)) }
            storeFile = file(p["storeFile"]!!.toString())   // например, app/upload-keystore.jks
            storePassword = p["storePassword"]?.toString()
            keyAlias = p["keyAlias"]?.toString()
            keyPassword = p["keyPassword"]?.toString()
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") { }
    }
}

flutter {
    source = "../.."
}

// ==== Копирование .aab туда, где его ждёт flutter ====

// Корень Flutter-проекта (папка drink_story)
val flutterProjectRoot = rootProject.projectDir.parentFile!!

// Задача: скопировать .aab из android/app/build/... в build/app/...
val copyBundleToFlutter by tasks.register<Copy>("copyBundleToFlutter") {
    from("$buildDir/outputs/bundle/release")
    include("*.aab")
    into(File(flutterProjectRoot, "build/app/outputs/bundle/release"))
}

// Когда Gradle создаст задачу signReleaseBundle, подвешиваем к ней copyBundleToFlutter
tasks.whenTaskAdded {
    if (name == "signReleaseBundle") {
        finalizedBy(copyBundleToFlutter)
    }
}
