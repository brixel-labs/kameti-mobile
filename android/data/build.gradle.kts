// Supabase-backed implementations of the repository interfaces. Only :app
// depends on this module.
plugins {
    id("kameti.android.library")
}

android {
    testOptions {
        // supabase-kt logs through android.util.Log, which is a stub in JVM tests.
        unitTests.isReturnDefaultValues = true
    }
}

dependencies {
    implementation(project(":core"))
    implementation(project(":domain"))
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.auth)
    implementation(libs.supabase.realtime)
    implementation(libs.supabase.functions)
    implementation(libs.ktor.client.okhttp)
    testImplementation(libs.ktor.client.mock)
}
