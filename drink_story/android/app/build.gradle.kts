// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ivarte.storystroll"

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
        applicationId = "com.ivarte.storystroll"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // key.properties должен лежать в android/key.properties (относительно каталога android)
            val keystoreFile = rootProject.file("key.properties")
            require(keystoreFile.exists()) { "key.properties not found at android/key.properties" }

            val p = Properties().apply { load(FileInputStream(keystoreFile)) }
            storeFile = file(p["storeFile"]!!.toString())     // напр. app/keystore.jks
            storePassword = p["storePassword"]?.toString()
            keyAlias = p["keyAlias"]?.toString()
            keyPassword = p["keyPassword"]?.toString()
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            // без fallback на debug — обязательно
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") { }
    }
}

flutter {
    source = "../.."
}

// Post-bundle task: copy app-release.aab to project-level build/app/outputs/bundle/release/
// so that Flutter tool can find it in the expected location
afterEvaluate {
    val bundleRelease = tasks.named("bundleRelease")
    val copyTask = tasks.register("copyReleaseBundleToProjectBuild") {
        doLast {
            val srcFile = file("${buildDir}/outputs/bundle/release/app-release.aab")
            val destDir = file("../../build/app/outputs/bundle/release")
            if (srcFile.exists()) {
                destDir.mkdirs()
                srcFile.copyTo(File(destDir, "app-release.aab"), overwrite = true)
                println("Copied AAB to: ${destDir.absolutePath}/app-release.aab")
            } else {
                println("Warning: source AAB not found at ${srcFile.absolutePath}")
            }
        }
    }
    bundleRelease.get().finalizedBy(copyTask)
}
