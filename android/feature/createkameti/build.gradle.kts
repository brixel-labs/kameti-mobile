// The create-kameti wizard.
plugins {
    id("kameti.android.feature")
}

dependencies {
    // BackHandler: the system Back button steps back through the wizard.
    implementation(libs.androidx.activity.compose)
}
