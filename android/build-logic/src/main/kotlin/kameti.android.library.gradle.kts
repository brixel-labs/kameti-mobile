// An Android library without Compose (:data).
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = kametiNamespace
    compileSdk = KametiBuild.COMPILE_SDK
    defaultConfig {
        minSdk = KametiBuild.MIN_SDK
    }
    compileOptions {
        sourceCompatibility = KametiBuild.JAVA
        targetCompatibility = KametiBuild.JAVA
    }
}

configureKotlinJvmTarget()
addUnitTestDependencies()
