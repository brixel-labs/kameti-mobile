package com.brixel.kameti.feature.shell

import com.brixel.kameti.domain.AppNotification
import com.brixel.kameti.domain.KeyValueStorage
import kotlinx.coroutines.flow.MutableStateFlow

/** A notification the user tapped, waiting for the app to open it. */
data class PushTap(val kind: String, val kametiId: String?) {
    /** Where a tap leads: requests and invitations open the Inbox, the rest open their kameti. */
    sealed interface Destination {
        data object Inbox : Destination
        data class Kameti(val id: String) : Destination
    }

    val destination: Destination
        get() = if (kametiId != null && AppNotification.opensKameti(kind)) Destination.Kameti(kametiId) else Destination.Inbox
}

/**
 * The app's push state, shared between the app module (Firebase, the
 * messaging service) and the screens: this phone's FCM token, taps, and
 * whether the in-app prompt was shown.
 */
object PushCenter {
    /** This phone's FCM registration token, set by the app module. `null` without Firebase. */
    val token = MutableStateFlow<String?>(null)

    /** The last tapped notification, cleared once it's opened. */
    val pendingTap = MutableStateFlow<PushTap?>(null)

    /** Where [hasAsked] is kept; the app module sets it at start. */
    var storage: KeyValueStorage? = null

    /** Whether the in-app "Know when it matters" prompt was already shown. */
    var hasAsked: Boolean
        get() = storage?.read(ASKED_KEY) == "true"
        set(value) {
            storage?.write(ASKED_KEY, value.toString())
        }

    /** From the app module when a notification is tapped. */
    fun handleTap(kind: String?, kametiId: String?) {
        pendingTap.value = PushTap(kind.orEmpty(), kametiId)
    }

    private const val ASKED_KEY = "kameti.push.asked"

    /** The keys a push carries (`send-push` puts the notification's kind and kameti in its data). */
    const val EXTRA_KIND = "kind"
    const val EXTRA_KAMETI_ID = "kameti_id"
}
