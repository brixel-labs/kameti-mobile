package com.brixel.kameti.domain

/** A row changed on the server (a payment, a member, a notification…). */
data class LiveChange(
    val table: String,
    /** The kameti it belongs to, when the row says so. */
    val kametiId: String?,
)

/** Live updates from the backend, so screens refresh themselves. */
interface LiveUpdatesRepository {
    /** Starts listening; [onChange] is called for every change the user may see. */
    suspend fun start(onChange: (LiveChange) -> Unit)
    suspend fun stop()
}

/** For builds without a backend: nothing ever changes on its own. */
class UnavailableLiveUpdates : LiveUpdatesRepository {
    override suspend fun start(onChange: (LiveChange) -> Unit) {}
    override suspend fun stop() {}
}
