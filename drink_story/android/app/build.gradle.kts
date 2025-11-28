
import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.ivarte.storystroll2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.ivarte.storystroll2"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            // Use Gradle's file(...) so relative paths are resolved against the module
            // project directory (android/app) rather than the Gradle daemon working dir.
            storeFilePath?.let { storeFile = file(it) }

            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        getByName("debug") {
            // если не нужно подписывать debug тем же ключом — можно убрать эту строку
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // ВЫРАВНИВАЕМ JVM: и Java, и Kotlin — на 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

// Ensure Flutter tooling can find the AAB where it expects it.
// Gradle produces the bundle under `android/app/build/outputs/...`,
// but Flutter sometimes looks for `build/app/outputs/...` at the Flutter project root.
// Add a small Copy task that runs after `bundleRelease` to place a copy
// at the Flutter-expected location so `flutter build appbundle` exits 0.
tasks.register<org.gradle.api.tasks.Copy>("copyBundleToFlutter") {
    val src = file("$buildDir/outputs/bundle/release/app-release.aab")
    // rootProject here refers to the Android Gradle root (android/). The Flutter
    // project root is the parent of that directory, so use `project.rootDir.parentFile`
    // to target the Flutter `build/` folder where the Flutter tooling looks.
    val flutterRoot = project.rootDir.parentFile
    val destDir = file("${flutterRoot.absolutePath}/build/app/outputs/bundle/release")
    from(src)
    into(destDir)
    doFirst {
        println("[copyBundleToFlutter] src=$src, dest=$destDir")
    }
}

// Run the copy after the bundle is produced.
tasks.matching { it.name == "bundleRelease" }.configureEach {
    finalizedBy("copyBundleToFlutter")
}
