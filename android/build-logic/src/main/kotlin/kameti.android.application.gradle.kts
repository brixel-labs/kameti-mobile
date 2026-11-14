// The thin app module: wiring, sign-in providers, push, config, icons.
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = KametiBuild.BASE_PACKAGE
    compileSdk = KametiBuild.COMPILE_SDK
    defaultConfig {
        applicationId = KametiBuild.BASE_PACKAGE
        minSdk = KametiBuild.MIN_SDK
        targetSdk = KametiBuild.TARGET_SDK
    }
    compileOptions {
        sourceCompatibility = KametiBuild.JAVA
        targetCompatibility = KametiBuild.JAVA
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

configureKotlinJvmTarget()
addUnitTestDependencies()
addComposeDependencies()
