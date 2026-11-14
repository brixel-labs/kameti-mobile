package com.brixel.kameti.domain

import com.brixel.kameti.core.KametiClock
import com.brixel.kameti.core.Timestamp
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * What Profile shows, kept on the phone per account so the screen opens
 * instantly without calling the server. It's filled after sign-in, updated
 * whenever the app saves or reloads something it holds, refreshed by pull to
 * refresh, and cleared on sign-out.
 */
@Serializable
data class ProfileSnapshot(
    val profile: Profile? = null,
    val kametis: List<Kameti>? = null,
    val people: List<Contact>? = null,
    val signIns: List<SignIn>? = null,
    val notificationPreferences: NotificationPreferences? = null,
    /** Set once the "What should we call you?" prompt was shown after sign-in. */
    val namePrompted: Boolean? = null,
    val savedAt: Timestamp? = null,
) {
    @Serializable
    data class SignIn(val provider: String, val email: String? = null)

    val signInMethods: List<SignInMethod>?
        get() = signIns?.mapNotNull { item ->
            SignInMethod.Provider.of(item.provider)?.let { SignInMethod(it, item.email) }
        }
}

/** Small on-device text storage (SharedPreferences in the app, a map in tests). */
interface KeyValueStorage {
    fun read(key: String): String?
    fun write(key: String, value: String)
    fun remove(key: String)
}

class InMemoryKeyValueStorage : KeyValueStorage {
    private val values = java.util.concurrent.ConcurrentHashMap<String, String>()
    override fun read(key: String): String? = values[key]
    override fun write(key: String, value: String) { values[key] = value }
    override fun remove(key: String) { values.remove(key) }
}

class ProfileCache(
    private val storage: KeyValueStorage = InMemoryKeyValueStorage(),
    private val clock: KametiClock = KametiClock(),
) {
    private val json = Json { ignoreUnknownKeys = true }
    private fun key(userId: String) = "kameti.profileCache.$userId"

    fun load(userId: String): ProfileSnapshot {
        val text = storage.read(key(userId)) ?: return ProfileSnapshot()
        return try {
            json.decodeFromString<ProfileSnapshot>(text)
        } catch (_: Exception) {
            ProfileSnapshot()
        }
    }

    /** Reads, changes and writes back the cached snapshot. */
    fun update(userId: String, change: (ProfileSnapshot) -> ProfileSnapshot) {
        val snapshot = change(load(userId)).copy(savedAt = clock.now())
        storage.write(key(userId), json.encodeToString(snapshot))
    }

    fun setSignInMethods(userId: String, methods: List<SignInMethod>) {
        update(userId) { snapshot ->
            snapshot.copy(signIns = methods.map { ProfileSnapshot.SignIn(it.provider.rawValue, it.email) })
        }
    }

    fun clear(userId: String) = storage.remove(key(userId))
}
