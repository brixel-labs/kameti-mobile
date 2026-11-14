package com.brixel.kameti.domain

import com.brixel.kameti.core.Day
import kotlinx.coroutines.flow.Flow

// Repository interfaces. Features depend on these, never on the Supabase
// implementations, so every screen and view model can be tested with a fake.
// All of them throw only `Failure`.
//
// Writes are Postgres RPCs; reads use row-level-secured tables and views.

/** Kametis, members, slots and shares. */
interface KametiRepository {
    /** Every kameti the user owns or has joined (the backend decides). */
    suspend fun listKametis(): List<Kameti>
    suspend fun kameti(id: String): Kameti
    suspend fun members(kametiId: String): List<Member>
    suspend fun slots(kametiId: String): List<Slot>
    suspend fun shares(kametiId: String): List<Share>

    suspend fun createKameti(new: NewKameti): Kameti

    /** Draft only for structure; name, description and due day also while active. */
    suspend fun updateKameti(id: String, changes: KametiChanges): Kameti

    /** Validates FR-12 on the server; fails with `kameti_not_ready`. */
    suspend fun startKameti(id: String): Kameti

    /**
     * Owner only (§6.11): hides it from the running lists and makes it
     * read-only for everyone. Fails with `kameti_already_archived`.
     */
    suspend fun archiveKameti(id: String): Kameti

    /**
     * "Edit setup": a started kameti back to a draft, before its first month
     * and with nothing recorded (`reopen_kameti`).
     */
    suspend fun reopenKameti(id: String): Kameti

    /**
     * Owner only: back to the state it was archived from. Fails with
     * `kameti_not_archived` or `kameti_name_taken`.
     */
    suspend fun restoreKameti(id: String): Kameti

    /**
     * Owner only (FR-13): a new draft with the same settings, members, shares
     * and payout order, and no payments. Fails with `kameti_name_taken`.
     */
    suspend fun duplicateKameti(id: String, name: String, startMonth: Day): Kameti

    suspend fun addMember(kametiId: String, new: NewMember): Member
    suspend fun updateMember(id: String, changes: MemberChanges): Member
    suspend fun removeMember(id: String)

    /**
     * Replaces a slot's shares. The server checks the sum equals C, the
     * Rs 1,000 steps, at most 4 sharers and the member slot limit.
     */
    suspend fun setSlotShares(slotId: String, shares: List<ShareInput>): List<Share>

    /**
     * FR-33: moves a running kameti's share to another member from
     * [fromMonth] on; returns the new holder's share. The note is the optional
     * settlement note, saved as a private note.
     */
    suspend fun transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?): Share

    /** New payout order: slot ids in month order (1..N). */
    suspend fun reorderSlots(kametiId: String, slotIdsInOrder: List<String>): List<Slot>
}

/** The backend's calculated views. */
interface LedgerRepository {
    suspend fun memberBalances(kametiId: String): List<MemberBalanceRow>
    suspend fun memberMonths(kametiId: String, memberId: String?): List<MemberMonthRow>
    suspend fun monthCollections(kametiId: String): List<MonthCollectionRow>
}

/** Payments and payouts. Append-only; corrections are voids. */
interface PaymentsRepository {
    suspend fun payments(kametiId: String): List<Payment>
    suspend fun payouts(kametiId: String): List<Payout>

    suspend fun recordPayment(new: NewPayment): Payment

    /** Tap to settle: all items in one transaction. */
    suspend fun recordPayments(
        kametiId: String,
        receivedOn: Day,
        items: List<BatchPaymentItem>,
        method: PaymentMethod,
    ): List<Payment>

    suspend fun voidPayment(id: String, reason: String): Payment

    suspend fun recordPayout(new: NewPayout): Payout
    suspend fun voidPayout(id: String, reason: String): Payout
}

/** Invites and joining. */
interface InvitesRepository {
    // Owner
    suspend fun createInvite(memberId: String): InviteLink
    suspend fun resendInvite(memberId: String): InviteLink
    suspend fun revokeInvite(memberId: String): Member
    suspend fun approveJoin(memberId: String): Member
    suspend fun declineJoin(memberId: String): Member
    suspend fun unlinkMember(memberId: String): Member

    /**
     * Emails the link. `false` means email isn't configured on the server
     * (the link is still valid: share it by hand).
     */
    suspend fun sendInviteEmail(link: InviteLink): Boolean
    suspend fun invites(kametiId: String): List<Invite>

    // Invitee: exactly one of `token` (or the 6-character code) and `inviteId`.
    suspend fun previewInvite(token: String?, inviteId: String?): InvitePreview
    suspend fun acceptInvite(token: String?, inviteId: String?): Member
    suspend fun declineInvite(token: String?, inviteId: String?): Member
    suspend fun myInvitations(): List<MyInvitation>
}

interface AuditRepository {
    /** Newest first. */
    suspend fun audit(kametiId: String, limit: Int): List<AuditEntry>
}

interface ProfileRepository {
    suspend fun myProfile(userId: String): Profile

    /** The name other people see (1–80 characters). */
    suspend fun updateDisplayName(userId: String, name: String): Profile
}

/** The owner's private contact list. Read only. */
interface ContactsRepository {
    suspend fun contacts(): List<Contact>
}

/** Sign-in state and sign-in methods. */
interface AuthRepository {
    /** The signed-in user's id, or `null`. */
    val currentUserId: String?

    /** Emits the current user id first, then every change. */
    fun userIdChanges(): Flow<String?>

    /** Native Google sign-in. `false` means the user closed the sheet. */
    suspend fun signInWithGoogle(): Boolean


    /** Local development only: email and password for seeded test users. */
    suspend fun signInWithPassword(email: String, password: String)
    suspend fun signOut()

    /**
     * How the signed-in account can sign in (Apple, Google, email), with
     * the email each one uses. Empty when unknown.
     */
    suspend fun signInMethods(): List<SignInMethod>
}

/** One way to sign in to the account. */
data class SignInMethod(val provider: Provider, val email: String?) {
    enum class Provider(val rawValue: String) {
        Apple("apple"), Google("google"), Email("email");

        companion object {
            fun of(rawValue: String): Provider? = entries.firstOrNull { it.rawValue == rawValue }
        }
    }
}
