// Typed routes, tabs and deep links. No UI, no other layers.
plugins {
    id("kameti.jvm.library")
}

dependencies {
    api(project(":core"))
    api(libs.kotlinx.coroutines.core)
}
