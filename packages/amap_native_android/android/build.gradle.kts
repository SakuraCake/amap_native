import groovy.json.JsonSlurper
import java.io.File

group = "ink.qichen.amap_native"
version = "0.1.2"

fun findFlutterPluginDependencies(): File? {
    val candidates = listOf(
        rootProject.projectDir.resolve("../.flutter-plugins-dependencies"),
        rootProject.projectDir.resolve(".flutter-plugins-dependencies"),
        project.projectDir.resolve("../../../.flutter-plugins-dependencies")
    )
    return candidates.map { it.canonicalFile }.firstOrNull { it.isFile }
}

val useNaviSdk: Boolean = findFlutterPluginDependencies()?.let { file ->
    runCatching {
        val root = JsonSlurper().parse(file) as Map<*, *>
        val plugins = root["plugins"] as? Map<*, *> ?: emptyMap<Any?, Any?>()
        val android = plugins["android"] as? List<*> ?: emptyList<Any?>()
        android.any { (it as? Map<*, *>)?.get("name") == "amap_native_navi" }
    }.getOrDefault(false)
} ?: false
logger.lifecycle(
    "AMap navigation SDK: ${if (useNaviSdk) "enabled" else "disabled"} " +
        "(from pubspec dependency amap_native_navi)"
)

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "ink.qichen.amap_native"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs(
                "src/main/kotlin",
                if (useNaviSdk) "src/navi/kotlin" else "src/base/kotlin"
            )
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    if (useNaviSdk) {
        implementation("com.amap.api:navi-3dmap-location-search:11.3.100_3dmap11.3.100_loc11.3.000_sea9.8.1")
    } else {
        implementation("com.amap.api:3dmap-location-search:11.3.100_loc11.3.101_sea9.8.1")
    }
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.lifecycle:lifecycle-common:2.8.7")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}
