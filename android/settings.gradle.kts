// The Android app mirrors ios/KametiKit: one Gradle module per Swift target.
// Layers depend inward only:
//
//   :feature:* -> :ui, :domain, :core            (never :data)
//   :data      -> :domain, :core                 (supabase-kt lives here)
//   :domain    -> :core                          (models + repository interfaces)
//
// :app is the one place that wires :data into the features.
pluginManagement {
    includeBuild("build-logic")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.FAIL_ON_PROJECT_REPOS
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "kameti"

include(
    ":app",
    ":core",
    ":domain",
    ":ui",
    ":data",
    ":navigation",
    ":testsupport",
    ":feature:auth",
    ":feature:home",
    ":feature:kametidetail",
    ":feature:createkameti",
    ":feature:invites",
    ":feature:shell",
)
