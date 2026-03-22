buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // This is usually already there, but ensure it exists:
        classpath("com.android.tools.build:gradle:8.1.1") // Or your current version
        
        // 👇 ADD THIS LINE FOR FIREBASE 👇
        classpath("com.google.gms:google-services:4.4.0")
    }
}



allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
