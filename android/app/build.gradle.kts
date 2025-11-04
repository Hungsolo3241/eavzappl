val kotlin_version = "2.2.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.multidex:multidex:2.0.1")  // ← ADD THIS
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

android {
    namespace = "com.blerdguild.eavzappl"
    compileSdk = 35  // ← CHANGE to latest stable
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.blerdguild.eavzappl"
        minSdk = 21  // ← CRITICAL: Change from 30 to 21
        targetSdk = 35  // ← CHANGE to latest
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // ← ADD THIS
    }

    buildTypes {
        release {
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}