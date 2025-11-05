val kotlin_version = "2.1.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

android {
    namespace = "com.blerdguild.eavzappl"
    compileSdk = 36
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

    // Resolve flutter.minSdkVersion safely from project properties (string or int).
    // Fallback to 21 if not found or not parseable.
    val flutterMinSdk: Int = run {
        val prop = project.findProperty("flutter.minSdkVersion")
        when (prop) {
            is String -> prop.toIntOrNull()
            is Int -> prop
            else -> null
        } ?: 24
    }
    minSdk = flutterMinSdk

    targetSdk = 34

    // Resolve versionCode/versionName safely too
    val flutterVersionCode: Int = (project.findProperty("flutter.versionCode") as? String)?.toIntOrNull()
        ?: (project.findProperty("flutter.versionCode") as? Int)
        ?: 1
    versionCode = flutterVersionCode

    versionName = project.findProperty("flutter.versionName") as? String ?: "1.0"

    multiDexEnabled = true
}


    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
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
