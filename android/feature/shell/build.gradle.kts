// The signed-in app: tabs, routes to screens, Profile and notifications.
plugins {
    id("kameti.android.feature")
}

dependencies {
    implementation(project(":navigation"))
    implementation(project(":feature:auth"))
    implementation(project(":feature:home"))
    implementation(project(":feature:kametidetail"))
    implementation(project(":feature:createkameti"))
    implementation(project(":feature:invites"))
    implementation(libs.androidx.activity.compose)
}
