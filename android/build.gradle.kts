allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ADD THIS
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(name)
    )
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}