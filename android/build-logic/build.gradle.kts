// Convention plugins: every module applies one of the `kameti.*` plugins in
// src/main/kotlin instead of repeating SDK levels, Compose and test setup.
plugins {
    `kotlin-dsl`
}

dependencies {
    implementation(libs.android.gradle.plugin)
    implementation(libs.kotlin.gradle.plugin)
    implementation(libs.kotlin.serialization.gradle.plugin)
    implementation(libs.compose.compiler.gradle.plugin)
}
