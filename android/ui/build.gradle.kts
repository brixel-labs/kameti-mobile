// The design system: tokens generated from design-tokens/tokens.json and the
// K* components. Screens are built only from these.
plugins {
    id("kameti.android.compose")
}

dependencies {
    api(project(":core"))
    // The icon set behind KIcons. Feature code names icons through KIcons only.
    implementation(libs.compose.material.icons)
    implementation(libs.kotlinx.coroutines.android)
}
