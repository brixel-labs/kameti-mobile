plugins {
    id("kameti.android.application")
}

android {
    defaultConfig {
        // versionCode is one integer that only ever increases (see git-workflow.md).
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    implementation(project(":core"))
    implementation(project(":domain"))
    implementation(project(":ui"))
    implementation(project(":data"))
    implementation(project(":navigation"))
    implementation(project(":testsupport"))
    implementation(project(":feature:auth"))
    implementation(project(":feature:shell"))
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.kotlinx.coroutines.android)
    // Google's account sheet (Credential Manager). The token goes to Supabase in :data.
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services)
    implementation(libs.googleid)
}
