// Home: the kameti cards and invitations.
plugins {
    id("kameti.android.feature")
}

dependencies {
    implementation(project(":feature:kametidetail"))
    implementation(project(":feature:invites"))
}
