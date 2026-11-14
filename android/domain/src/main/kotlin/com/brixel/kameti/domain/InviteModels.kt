package com.brixel.kameti.domain

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.Timestamp
import java.time.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Matches `public.invite_status`. */
@Serializable
enum class InviteStatus {
    @SerialName("pending") Pending,
    @SerialName("accepted") Accepted,
    @SerialName("declined") Declined,
    @SerialName("revoked") Revoked,
    @SerialName("superseded") Superseded,
}

/**
 * What happened to an invite's email (`public.email_delivery`), reported by
 * Resend. `Bounced` or `Complained` means it didn't arrive (E39b).
 */
@Serializable
enum class EmailDelivery {
    @SerialName("sent") Sent,
    @SerialName("delivered") Delivered,
    @SerialName("delayed") Delayed,
    @SerialName("bounced") Bounced,
    @SerialName("complained") Complained;

    val didNotArrive: Boolean get() = this == Bounced || this == Complained
}

/**
 * Row of `public.invites`: owner-only. The token itself is never stored in
 * readable form, so "copy link" later means resending (a new link).
 */
@Serializable
data class Invite(
    val id: String,
    val kametiId: String,
    val memberId: String,
    val status: InviteStatus,
    val expiresAt: Timestamp,
    val sendCount: Int,
    val email: String? = null,
    val sentAt: Timestamp? = null,
    /** The email the invitee signed in with. Show it masked. */
    val acceptedEmail: String? = null,
    /** What happened to the last invite email; `null` when none was sent. */
    val deliveryStatus: EmailDelivery? = null,
) {
    /**
     * Expired is derived: pending past its expiry (the member stays
     * `invited` on the backend).
     */
    fun isExpired(now: Instant): Boolean = status == InviteStatus.Pending && expiresAt < now

    companion object {
        /**
         * The columns the app may read (the table hides the token and code
         * hashes, so `select *` is refused).
         */
        const val COLUMNS = "id,kameti_id,member_id,status,expires_at,send_count,email,sent_at,accepted_email,delivery_status"
    }
}

/**
 * Result of `create_invite` / `resend_invite`. [token] and [code] are
 * readable exactly once: hand them to the email function or the owner.
 */
@Serializable
data class InviteLink(
    val inviteId: String,
    val memberId: String,
    val token: String,
    val code: String,
    val link: String,
    val expiresAt: Timestamp,
    val email: String? = null,
)

/** One share of the invited member, shown before they accept. */
@Serializable
data class InviteShare(val payoutMonthIndex: Int, val monthlyAmount: Money)

/** Result of `preview_invite`: what the invitee sees on the accept screen. */
@Serializable
data class InvitePreview(
    val inviteId: String,
    val status: String,
    val expired: Boolean,
    val expiresAt: Timestamp,
    val emailMatches: Boolean,
    val kametiName: String,
    val ownerName: String,
    val memberName: String,
    val shares: List<InviteShare> = emptyList(),
    /**
     * First day of month 1. `null` from a backend without the
     * `invite_preview_dates` migration.
     */
    val startMonth: Day? = null,
    /** N, the number of months (and slots). */
    val monthsN: Int? = null,
    /**
     * E39: the signed-in account is already in this kameti, on the member
     * record named [alreadyMemberName], so accepting would fail.
     */
    val alreadyMember: Boolean? = null,
    val alreadyMemberName: String? = null,
    /** The signed-in account runs this kameti. */
    val isOwner: Boolean? = null,
) {
    /** Still open: pending and not past its expiry. */
    val isOpen: Boolean get() = status == "pending" && !expired

    /** Open, and nothing stops this account from joining. */
    val canJoin: Boolean get() = isOpen && alreadyMember != true && isOwner != true
}

/**
 * Row of `list_my_invitations()`: live invites addressed to the signed-in
 * account's email.
 */
@Serializable
data class MyInvitation(
    val inviteId: String,
    val kametiName: String,
    val ownerName: String,
    val memberName: String,
    val expiresAt: Timestamp,
    val createdAt: Timestamp,
) {
    val id: String get() = inviteId
}
