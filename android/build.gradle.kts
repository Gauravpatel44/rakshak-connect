allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Use absolute path to avoid cross-drive relative path issues on Windows (Gradle 9+)
// rootProject.projectDir = sos_app/android, so one parentFile goes to sos_app/
val absoluteBuildDir = rootProject.projectDir.parentFile.resolve("build")
rootProject.layout.buildDirectory.set(absoluteBuildDir)

subprojects {
    val newSubprojectBuildDir = absoluteBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
