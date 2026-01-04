allprojects {
    repositories {
        mavenCentral()
        mavenLocal()
        //佳博SDK仓库
        maven {
            url = uri("http://118.31.6.84:8081/repository/maven-public/")
            isAllowInsecureProtocol = true
        }
        maven {
            url = uri("https://maven.aliyun.com/nexus/content/groups/public/")
        }
        maven {
            url = uri("https://maven.aliyun.com/nexus/content/repositories/jcenter")
        }
        maven {
            url = uri("https://maven.aliyun.com/nexus/content/repositories/google")
        }
        maven {
            url = uri("https://maven.aliyun.com/nexus/content/repositories/gradle-plugin")
        }
        
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
