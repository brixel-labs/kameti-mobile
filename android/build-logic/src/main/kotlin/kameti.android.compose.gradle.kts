// An Android library with Compose (:ui).
plugins {
    id("kameti.android.library")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    buildFeatures {
        compose = true
    }
}

addComposeDependencies()
