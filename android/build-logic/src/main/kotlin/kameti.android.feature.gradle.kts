// A feature module: screens and their view models. Features see the domain
// and the design system, never :data, so every view model is tested with the
// stub repositories in :testsupport.
plugins {
    id("kameti.android.compose")
}

dependencies {
    "implementation"(project(":core"))
    "implementation"(project(":domain"))
    "implementation"(project(":ui"))
    "implementation"(catalog.findLibrary("kotlinx-coroutines-android").get())
    "implementation"(catalog.findLibrary("androidx-lifecycle-viewmodel-compose").get())
    "implementation"(catalog.findLibrary("androidx-lifecycle-runtime-compose").get())
    "testImplementation"(project(":testsupport"))
}
