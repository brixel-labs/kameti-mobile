import java.util.Properties

plugins {
    id("kameti.android.application")
    alias(libs.plugins.google.services) apply false
}

// google-services.json is git-ignored (it comes from the Firebase console).
// Without it the app builds and runs, just without push.
if (file("google-services.json").exists()) apply(plugin = "com.google.gms.google-services")

android {
    defaultConfig {
        // versionCode is one integer that only ever increases (see git-workflow.md).
        versionCode = 2
        versionName = "1.0"
    }
    // The upload key is not in git. Put its details in android/keystore.properties:
    //   storeFile=/absolute/path/to/kameti-upload.jks
    //   storePassword=…   keyAlias=…   keyPassword=…
    // Without that file a release build still assembles, unsigned.
    val keystoreFile = rootProject.file("keystore.properties")
    val keystore = Properties().apply { if (keystoreFile.exists()) keystoreFile.inputStream().use(::load) }
    signingConfigs {
        if (keystoreFile.exists()) {
            create("release") {
                storeFile = file(keystore.getProperty("storeFile"))
                storePassword = keystore.getProperty("storePassword")
                keyAlias = keystore.getProperty("keyAlias")
                keyPassword = keystore.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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
    // Sample data for the demo flavor: debug builds only (src/debug/DemoBackend.kt).
    debugImplementation(project(":testsupport"))
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
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.messaging)
}
