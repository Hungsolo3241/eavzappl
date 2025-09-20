val kotlin_version = "2.2.0" // Or your desired Kotlin version

plugins {
    id("com.android.application") version "8.12.3" apply false // Or your Android Gradle Plugin version
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false // Example Kotlin version
    id("com.google.gms.google-services") version "4.4.3" apply false
}

// ... rest of your file

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
