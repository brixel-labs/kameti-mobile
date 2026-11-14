package com.brixel.kameti.domain

import com.brixel.kameti.core.Failure
import kotlinx.serialization.Serializable

/**
 * What deleting the account would do (`account_deletion_check()`,
 * REQUIREMENTS §5.5): running kametis the user owns block it; drafts and
 * saved people are deleted; member records are unlinked but stay in the
 * owners' ledgers; past kametis are kept for their members.
 */
@Serializable
data class AccountDeletionCheck(
    val canDelete: Boolean,
    val blockingKametis: List<KametiRef> = emptyList(),
    val draftsToDelete: List<KametiRef> = emptyList(),
    val ownedKametisKept: List<KametiRef> = emptyList(),
    val membershipsToUnlink: Int = 0,
    val contactsToDelete: Int = 0,
) {
    @Serializable
    data class KametiRef(val id: String, val name: String, val status: KametiStatus? = null)
}

/** Deleting the signed-in account (the `delete-account` Edge Function). */
interface AccountRepository {
    suspend fun deletionCheck(): AccountDeletionCheck

    /**
     * Deletes the account. Fails with `owner_has_active_kametis` while the
     * user still runs a kameti. The app signs out afterwards.
     */
    suspend fun deleteAccount()
}

/** The default when no account backend is wired (older test setups). */
class UnavailableAccountRepository : AccountRepository {
    override suspend fun deletionCheck(): AccountDeletionCheck =
        throw Failure.Unknown("account deletion is not available")

    override suspend fun deleteAccount(): Unit = throw Failure.Unknown("account deletion is not available")
}
