package com.brixel.kameti.data

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Timestamp
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.InviteLink
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.InvitesRepository
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberViewLink
import com.brixel.kameti.domain.MyInvitation
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.Serializable

@Serializable
private class ViewLinkRow(val memberId: String, val token: String, val lastViewedAt: Timestamp? = null)

internal class SupabaseInvitesRepository(private val client: SupabaseClient) : InvitesRepository {
    private fun memberParam(id: String) = params("p_member_id" to text(id))

    override suspend fun createInvite(memberId: String): InviteLink = call {
        client.postgrest.rpc("create_invite", memberParam(memberId)).decodeAs()
    }

    override suspend fun resendInvite(memberId: String): InviteLink = call {
        client.postgrest.rpc("resend_invite", memberParam(memberId)).decodeAs()
    }

    override suspend fun revokeInvite(memberId: String): Member = call {
        client.postgrest.rpc("revoke_invite", memberParam(memberId)).decodeAs()
    }

    override suspend fun viewLink(memberId: String, rotate: Boolean): MemberViewLink = call {
        client.postgrest.rpc("member_view_link", params("p_member_id" to text(memberId), "p_rotate" to flag(rotate))).decodeAs()
    }

    override suspend fun viewLinks(kametiId: String): List<MemberViewLink> = call {
        client.from("member_view_links").select(Columns.raw("member_id,token,last_viewed_at")) {
            filter { eq("kameti_id", kametiId) }
        }.decodeList<ViewLinkRow>().map { MemberViewLink(it.memberId, MemberViewLink.BASE + it.token, it.lastViewedAt) }
    }

    override suspend fun turnOffViewLink(memberId: String) = call {
        client.postgrest.rpc("turn_off_member_view_link", memberParam(memberId))
        Unit
    }

    override suspend fun approveJoin(memberId: String): Member = call {
        client.postgrest.rpc("approve_join", memberParam(memberId)).decodeAs()
    }

    override suspend fun declineJoin(memberId: String): Member = call {
        client.postgrest.rpc("decline_join", memberParam(memberId)).decodeAs()
    }

    override suspend fun unlinkMember(memberId: String): Member = call {
        client.postgrest.rpc("unlink_member", memberParam(memberId)).decodeAs()
    }

    override suspend fun sendInviteEmail(link: InviteLink): Boolean = call {
        try {
            client.functions.invoke(
                "send-invites",
                params("invite_id" to text(link.inviteId), "token" to text(link.token), "code" to text(link.code)),
            )
            true
        } catch (error: RestException) {
            // 503 is email_not_configured: the link still works, share it by hand.
            if (error.statusCode == 503) false else throw Failure.Server("function_http_${error.statusCode}")
        }
    }

    override suspend fun invites(kametiId: String): List<Invite> = call {
        client.from("invites").select(Columns.raw(Invite.COLUMNS)) {
            filter { eq("kameti_id", kametiId) }
            order("created_at", Order.DESCENDING)
        }.decodeList()
    }

    override suspend fun previewInvite(token: String?, inviteId: String?): InvitePreview = call {
        client.postgrest.rpc("preview_invite", Params.inviteLookup(token, inviteId)).decodeAs()
    }

    override suspend fun acceptInvite(token: String?, inviteId: String?): Member = call {
        client.postgrest.rpc("accept_invite", Params.inviteLookup(token, inviteId)).decodeAs()
    }

    override suspend fun declineInvite(token: String?, inviteId: String?): Member = call {
        client.postgrest.rpc("decline_invite", Params.inviteLookup(token, inviteId)).decodeAs()
    }

    override suspend fun myInvitations(): List<MyInvitation> = call {
        client.postgrest.rpc("list_my_invitations").decodeList()
    }
}
