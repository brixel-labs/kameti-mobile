package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.domain.EmailDelivery
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.InviteLink
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.InviteShare
import com.brixel.kameti.domain.InviteStatus
import com.brixel.kameti.domain.InvitesRepository
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberViewLink
import com.brixel.kameti.domain.MyInvitation
import java.util.UUID
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put

/**
 * The demo's invites, mirroring the backend's invite RPCs closely enough to
 * try every screen: sending, resending and revoking (owner), approving a
 * join, and accepting or declining an invite addressed to the demo account.
 * Email is never "configured" here, so codes and links are shared by hand.
 */
class SampleInvitesRepository(
    private val kametis: SampleKametiRepository,
    private val contacts: SampleContactStore,
    private val log: SampleAuditLog = SampleAuditLog(),
) : InvitesRepository {
    private class Secret(val token: String, val code: String)

    private val lock = Any()
    private val now = SampleData.now
    private var invites = listOf(
        // Faisal: invited two days ago; the email bounced (E39b).
        Invite(
            "inv-f6", "family", "f6", InviteStatus.Pending, now.plusSeconds(12 * DAY), sendCount = 1,
            email = "faisal.iqbal@gmail.com", sentAt = now.minusSeconds(2 * DAY), deliveryStatus = EmailDelivery.Bounced,
        ),
        // Hira: accepted with a different (Apple private relay) email.
        Invite(
            "inv-f5", "family", "f5", InviteStatus.Accepted, now.plusSeconds(13 * DAY), sendCount = 1,
            email = "hira.malik@gmail.com", sentAt = now.minusSeconds(DAY), acceptedEmail = "x7d2k9q4mb@privaterelay.appleid.com",
        ),
        // An invite to the demo account itself.
        Invite(
            "inv-cz3", "cousins", "cz3", InviteStatus.Pending, now.plusSeconds(14 * DAY), sendCount = 1,
            email = SampleData.EMAIL, sentAt = now.minusSeconds(HOUR),
        ),
    )
    private val secrets = mutableMapOf("inv-cz3" to Secret("demo-cousins-invite-token-000000", "CZN7QK"))
    private var counter = 0

    private fun fail(code: String): Nothing = throw Failure.Server(code)
    private fun Invite.isMine() = email?.lowercase() == SampleData.EMAIL

    // Owner

    override suspend fun createInvite(memberId: String): InviteLink {
        val member = kametis.memberRow(memberId) ?: fail("not_found")
        if (member.joinStatus == JoinStatus.Joined || member.profileId != null) fail("member_already_joined")
        if (member.joinStatus == JoinStatus.PendingApproval) fail("approval_pending")
        val email = contacts.contact(member.contactId)?.email ?: fail("member_has_no_email")
        if (synchronized(lock) { invites.any { it.memberId == memberId && it.status == InviteStatus.Pending } }) {
            fail("invite_already_pending")
        }
        return issue(member, email, sendCount = 1)
    }

    override suspend fun resendInvite(memberId: String): InviteLink {
        val member = kametis.memberRow(memberId) ?: fail("not_found")
        if (member.joinStatus == JoinStatus.PendingApproval) fail("approval_pending")
        if (member.joinStatus == JoinStatus.Joined) fail("member_already_joined")
        val previous = synchronized(lock) { invites.lastOrNull { it.memberId == memberId } } ?: fail("no_invite")
        val email = contacts.contact(member.contactId)?.email ?: previous.email ?: ""
        if (email.isEmpty()) fail("member_has_no_email")
        synchronized(lock) {
            invites = invites.map {
                if (it.memberId == memberId && it.status == InviteStatus.Pending) it.copy(status = InviteStatus.Superseded) else it
            }
        }
        return issue(member, email, sendCount = previous.sendCount + 1)
    }

    override suspend fun revokeInvite(memberId: String): Member {
        val found = synchronized(lock) {
            val pending = invites.firstOrNull { it.memberId == memberId && it.status == InviteStatus.Pending }
            if (pending != null) invites = invites.map { if (it.id == pending.id) it.copy(status = InviteStatus.Revoked) else it }
            pending != null
        }
        if (!found) fail("no_pending_invite")
        val member = required(kametis.setJoin(memberId, JoinStatus.NotInvited, null))
        log.record(member.kametiId, "invite.revoke", entity = "invite", entityId = null, member = memberId)
        return member
    }

    override suspend fun approveJoin(memberId: String): Member {
        val row = kametis.memberRow(memberId)
        if (row?.joinStatus != JoinStatus.PendingApproval) fail("not_pending_approval")
        val member = required(kametis.setJoin(memberId, JoinStatus.Joined, row.profileId))
        log.record(member.kametiId, "member.approve_join", entity = "member", entityId = memberId, member = memberId)
        return member
    }

    override suspend fun declineJoin(memberId: String): Member {
        if (kametis.memberRow(memberId)?.joinStatus != JoinStatus.PendingApproval) fail("not_pending_approval")
        val member = required(kametis.setJoin(memberId, JoinStatus.Declined, null))
        log.record(member.kametiId, "member.decline_join", entity = "member", entityId = memberId, member = memberId)
        return member
    }

    override suspend fun unlinkMember(memberId: String): Member {
        val member = kametis.memberRow(memberId)
        if (member?.profileId == null) fail("member_not_linked")
        if (member.profileId == SampleData.USER_ID) fail("cannot_unlink_owner")
        return required(kametis.setJoin(memberId, JoinStatus.NotInvited, null))
    }

    /** Email isn't set up in the demo: the owner shares the code or link. */
    override suspend fun sendInviteEmail(link: InviteLink): Boolean = false

    /** The demo keeps one link per member for the session. */
    override suspend fun viewLink(memberId: String, rotate: Boolean): MemberViewLink {
        if (kametis.memberRow(memberId) == null) fail("not_found")
        val token = memberId.map { "%02x".format(it.code) }.joinToString("").repeat(64).take(64)
        return MemberViewLink(memberId, "https://kameti.fhbtechservices.com/v/$token")
    }

    override suspend fun turnOffViewLink(memberId: String) {}

    override suspend fun viewLinks(kametiId: String): List<MemberViewLink> = emptyList()

    override suspend fun invites(kametiId: String): List<Invite> =
        synchronized(lock) { invites.filter { it.kametiId == kametiId }.reversed() }

    // Invitee

    override suspend fun previewInvite(token: String?, inviteId: String?): InvitePreview {
        val invite = find(token, inviteId, live = false)
        val kameti = kametis.kametiRow(invite.kametiId) ?: fail("invite_not_found")
        val member = kametis.memberRow(invite.memberId) ?: fail("invite_not_found")
        val shares = kametis.shareRows(member.id, kameti.id)
            .mapNotNull { (share, slot) -> slot?.let { InviteShare(it.payoutMonthIndex, share.monthlyAmount) } }
            .sortedBy { it.payoutMonthIndex }
        val mine = kametis.myMember(kameti.id)
        return InvitePreview(
            inviteId = invite.id, status = (KametiJson.json.encodeToJsonElement<InviteStatus>(invite.status) as JsonPrimitive).content,
            expired = invite.isExpired(now), expiresAt = invite.expiresAt, emailMatches = invite.isMine(),
            kametiName = kameti.name, ownerName = SampleData.ownerNames[kameti.ownerId] ?: "", memberName = member.name,
            shares = shares, startMonth = kameti.startMonth, monthsN = kameti.monthsN,
            alreadyMember = mine != null, alreadyMemberName = mine?.name, isOwner = kameti.ownerId == SampleData.USER_ID,
        )
    }

    override suspend fun acceptInvite(token: String?, inviteId: String?): Member {
        val invite = find(token, inviteId, live = true)
        val kameti = kametis.kametiRow(invite.kametiId)
        if (kameti == null || kameti.status !in setOf(KametiStatus.Draft, KametiStatus.Active)) fail("kameti_not_joinable")
        if (kameti.ownerId == SampleData.USER_ID) fail("owner_cannot_join")
        val member = kametis.memberRow(invite.memberId)
        if (member == null || member.profileId != null || member.joinStatus in setOf(JoinStatus.Joined, JoinStatus.PendingApproval)) {
            fail("member_already_linked")
        }
        synchronized(lock) {
            invites = invites.map {
                if (it.id == invite.id) it.copy(status = InviteStatus.Accepted, acceptedEmail = SampleData.EMAIL) else it
            }
        }
        val status = if (invite.isMine()) JoinStatus.Joined else JoinStatus.PendingApproval
        return required(kametis.setJoin(member.id, status, SampleData.USER_ID))
    }

    override suspend fun declineInvite(token: String?, inviteId: String?): Member {
        val invite = find(token, inviteId, live = true)
        synchronized(lock) {
            invites = invites.map { if (it.id == invite.id) it.copy(status = InviteStatus.Declined) else it }
        }
        return required(kametis.setJoin(invite.memberId, JoinStatus.Declined, null))
    }

    override suspend fun myInvitations(): List<MyInvitation> {
        val live = synchronized(lock) {
            invites.filter { it.status == InviteStatus.Pending && !it.isExpired(now) && it.isMine() }
        }
        return live.mapNotNull { invite ->
            val kameti = kametis.kametiRow(invite.kametiId) ?: return@mapNotNull null
            val member = kametis.memberRow(invite.memberId) ?: return@mapNotNull null
            MyInvitation(
                inviteId = invite.id, kametiName = kameti.name, ownerName = SampleData.ownerNames[kameti.ownerId] ?: "",
                memberName = member.name, expiresAt = invite.expiresAt, createdAt = invite.sentAt ?: now,
            )
        }
    }

    // Helpers

    private fun issue(member: Member, email: String, sendCount: Int): InviteLink {
        val (invite, secret) = synchronized(lock) {
            counter += 1
            val id = "inv-new-$counter"
            val secret = Secret(UUID.randomUUID().toString().replace("-", ""), randomCode())
            val invite = Invite(
                id, member.kametiId, member.id, InviteStatus.Pending, now.plusSeconds(14 * DAY),
                sendCount = sendCount, email = email, sentAt = now,
            )
            invites = invites + invite
            secrets[id] = secret
            invite to secret
        }
        kametis.setJoin(member.id, JoinStatus.Invited, null)
        log.record(
            member.kametiId, "invite.create", entity = "invite", entityId = invite.id, member = member.id,
            after = buildJsonObject { put("member_id", member.id); put("email", email) },
        )
        return InviteLink(
            inviteId = invite.id, memberId = member.id, token = secret.token, code = secret.code,
            link = BASE + secret.token, expiresAt = invite.expiresAt, email = email,
        )
    }

    /** Like `private.find_invite`: by id (my email only), by a short code, or by token. */
    private fun find(token: String?, inviteId: String?, live: Boolean): Invite {
        val text = (token ?: "").trim()
        if (text.isEmpty() == (inviteId == null)) fail("invalid_invite")
        val invite = synchronized(lock) {
            when {
                inviteId != null -> invites.firstOrNull { it.id == inviteId && it.isMine() }
                text.length <= 8 -> invites.firstOrNull { secrets[it.id]?.code == text.uppercase() && it.status == InviteStatus.Pending }
                else -> invites.firstOrNull { secrets[it.id]?.token == text }
            }
        } ?: fail("invite_not_found")
        if (live) {
            if (invite.status != InviteStatus.Pending) fail("invite_not_active")
            if (invite.isExpired(now)) fail("invite_expired")
        }
        return invite
    }

    private fun required(member: Member?): Member = member ?: fail("not_found")

    private companion object {
        const val BASE = "https://kameti.fhbtechservices.com/join/"

        // No 0/O or 1/I, so a code read aloud can't be misheard.
        const val LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

        fun randomCode(): String = (0 until 6).map { LETTERS.random() }.joinToString("")
    }
}
