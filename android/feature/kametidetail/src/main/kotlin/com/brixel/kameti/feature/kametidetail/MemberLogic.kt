package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.InviteStatus
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.Share

/**
 * The rules behind adding, editing and removing members, kept apart from the
 * screens so they can be tested. They mirror the backend's `add_member`,
 * `update_member` and `remove_member`.
 */
internal object MemberLogic {
    /** Why a member can't be removed: what still ties them to the ledger. */
    data class RemovalBlock(val slots: Int, val payments: Int)

    /**
     * `null` when the member can be removed. Once a kameti has started, anyone
     * who holds a share or has a payment or payout (voided ones count too)
     * stays on the ledger, like the backend's `member_has_history`.
     */
    fun removalBlock(member: Member, data: KametiDetailData): RemovalBlock? {
        if (data.kameti.status == KametiStatus.Draft) return null
        val holdsShares = data.shares.any { it.memberId == member.id }
        val payments = data.payments.count { it.memberId == member.id } + data.payouts.count { it.memberId == member.id }
        if (!holdsShares && payments == 0) return null
        return RemovalBlock(DetailLogic.slotCount(member, data.shares), payments)
    }

    /** Saved people who aren't in this kameti yet, by name. */
    fun availableContacts(data: KametiDetailData): List<Contact> {
        val taken = data.members.mapNotNull { it.contactId }.toSet()
        return data.contacts.filter { it.id !in taken }.sortedBy { it.name.lowercase() }
    }

    fun contact(member: Member, data: KametiDetailData): Contact? = data.contacts.firstOrNull { it.id == member.contactId }

    /** 1–80 characters after trimming. */
    fun isValidName(name: String): Boolean = name.trim().length in 1..80

    /** Empty is fine (the email is optional); otherwise a simple shape check. */
    fun isValidEmail(email: String): Boolean {
        val value = email.trim()
        if (value.isEmpty()) return true
        val parts = value.split("@")
        return parts.size == 2 && parts[0].isNotEmpty() && "." in parts[1] && !parts[1].startsWith(".") &&
            !parts[1].endsWith(".") && " " !in value
    }

    /**
     * Empty is fine; otherwise digits with optional spaces, dashes and a
     * leading +, 7 to 15 digits.
     */
    fun isValidPhone(phone: String): Boolean {
        val value = phone.trim()
        if (value.isEmpty()) return true
        if (!value.all { it in "+0123456789 -" } || "+" in value.drop(1)) return false
        return value.count { it.isDigit() } in 7..15
    }

    /**
     * The fields that changed, as `update_member` expects them: `null` leaves
     * a field alone and an empty string clears it. `null` overall when
     * nothing changed.
     */
    fun changes(name: String, email: String, phone: String, member: Member, contact: Contact?): MemberChanges? {
        val newName = name.trim().takeIf { it != member.name }
        val newEmail = email.trim().takeIf { it.lowercase() != (contact?.email ?: "").lowercase() }
        val newPhone = phone.trim().takeIf { it != (contact?.phone ?: "") }
        if (newName == null && newEmail == null && newPhone == null) return null
        return MemberChanges(name = newName, email = newEmail, phone = newPhone)
    }
}

/**
 * Where a member stands with the app, worked out from their join status and
 * invites. Kept apart from the screen so it can be tested.
 */
internal sealed interface AccessState {
    /** The owner's own member row: nothing to invite. */
    data object Owner : AccessState
    data object Joined : AccessState
    data class NeedsApproval(val invitedEmail: String?, val acceptedEmail: String?) : AccessState
    data class Invited(val invite: Invite) : AccessState

    /** Not invited, declined or revoked. [email] is where an invite would go. */
    data class NotInvited(val email: String?, val declined: Boolean) : AccessState

    companion object {
        fun of(member: Member, data: KametiDetailData): AccessState {
            if (member.profileId == data.userId) return Owner
            val mine = data.invites.filter { it.memberId == member.id }
            val email = MemberLogic.contact(member, data)?.email
            return when (member.joinStatus) {
                JoinStatus.Joined -> Joined
                JoinStatus.PendingApproval -> {
                    val accepted = mine.firstOrNull { it.status == InviteStatus.Accepted }
                    NeedsApproval(accepted?.email, accepted?.acceptedEmail)
                }
                JoinStatus.Invited ->
                    mine.firstOrNull { it.status == InviteStatus.Pending }?.let(::Invited) ?: NotInvited(email, declined = false)
                JoinStatus.NotInvited, JoinStatus.Declined ->
                    NotInvited(email, declined = member.joinStatus == JoinStatus.Declined)
            }
        }

        /** Members "Invite all" would invite: not invited yet, with an email. */
        fun invitable(data: KametiDetailData): List<Member> =
            data.members.filter { (of(it, data) as? NotInvited)?.email != null }

        /** Members who can't be invited yet because they have no email. */
        fun missingEmail(data: KametiDetailData): Int =
            data.members.count { member -> (of(member, data) as? NotInvited)?.let { it.email == null } ?: false }
    }
}

/** The rules behind moving a share (FR-33), mirroring the backend's `transfer_share`. */
internal object TransferLogic {
    /** A member's shares that can still move: running kameti, not already ended. */
    fun movableShares(member: Member, data: KametiDetailData): List<Share> {
        if (data.kameti.status != KametiStatus.Active) return emptyList()
        return data.shares
            .filter { it.memberId == member.id && it.effectiveToMonth == null && firstMonth(it, data) != null }
            .sortedBy { payoutMonth(it, data) }
    }

    /**
     * The earliest month it can move from: this month (or month 1 before the
     * start), never before the share began. `null` once every month has passed.
     */
    fun firstMonth(share: Share, data: KametiDetailData): Int? {
        val current = data.current?.monthIndex
            ?: if (data.today.isBefore(data.kameti.startMonth)) 1 else data.kameti.monthsN + 1
        val first = maxOf(current, share.effectiveFromMonth)
        return first.takeIf { it <= data.kameti.monthsN }
    }

    fun payoutMonth(share: Share, data: KametiDetailData): Int =
        data.slots.firstOrNull { it.id == share.slotId }?.payoutMonthIndex ?: 0

    /**
     * Members who can take the share: not its holder, not already in that
     * slot, and under the slot limit.
     */
    fun candidates(share: Share, data: KametiDetailData): List<Member> = data.members.filter { member ->
        member.id != share.memberId &&
            data.shares.none { it.slotId == share.slotId && it.memberId == member.id && it.effectiveToMonth == null } &&
            DetailLogic.slotCount(member, data.shares) < data.kameti.maxSlotsPerMember
    }

    /** How much the current holder has paid so far (all their payments). */
    fun paidSoFar(member: Member, data: KametiDetailData): Money =
        data.balances.firstOrNull { it.memberId == member.id }?.totalPaid ?: Money.ZERO
}
