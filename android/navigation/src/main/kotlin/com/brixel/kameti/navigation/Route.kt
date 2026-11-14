package com.brixel.kameti.navigation

import com.brixel.kameti.core.RecordAction

/** The three tabs of the signed-in app. */
enum class AppTab { Home, Inbox, Profile }

/**
 * Every screen a tab's stack can show. Features push these without knowing
 * which feature draws them; `:feature:shell` maps each route to its screen.
 */
sealed interface Route {
    data class KametiDetail(val id: String) : Route

    /** A kameti opened on its Members tab: right after it starts, so the owner can send invites at once. */
    data class KametiMembers(val id: String) : Route

    /** A kameti opened straight into a recording action (Home's Record payment). */
    data class KametiAction(val id: String, val action: RecordAction) : Route

    /** The create-kameti wizard. */
    data object CreateKameti : Route

    /** The create wizard reopened on a saved draft. */
    data class ResumeDraft(val id: String) : Route
    data class Activity(val kametiId: String) : Route

    /** Home's archived kametis (§6.11). */
    data object ArchivedKametis : Route

    /** Profile's completed and cancelled kametis. */
    data object PastKametis : Route

    /** Profile's saved people. */
    data object MyPeople : Route

    /** Profile's notification settings. */
    data object NotificationSettings : Route

    /** An invite link token or the 6-character code. */
    data class Join(val token: String) : Route

    /** An invitation addressed to my email, from Home or Inbox. */
    data class Invitation(val id: String) : Route
}
