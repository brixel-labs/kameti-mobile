import Foundation
import Functions
import KametiCore
import KametiDomain
import Supabase

public final class SupabaseInvitesRepository: InvitesRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    private func memberParam(_ id: String) -> RPCParams { ["p_member_id": .string(id)] }

    public func createInvite(memberId: String) async throws(Failure) -> InviteLink {
        try await run { try await client.rpc("create_invite", params: memberParam(memberId)).execute().value }
    }

    public func resendInvite(memberId: String) async throws(Failure) -> InviteLink {
        try await run { try await client.rpc("resend_invite", params: memberParam(memberId)).execute().value }
    }

    public func revokeInvite(memberId: String) async throws(Failure) -> Member {
        try await run { try await client.rpc("revoke_invite", params: memberParam(memberId)).execute().value }
    }

    public func approveJoin(memberId: String) async throws(Failure) -> Member {
        try await run { try await client.rpc("approve_join", params: memberParam(memberId)).execute().value }
    }

    public func declineJoin(memberId: String) async throws(Failure) -> Member {
        try await run { try await client.rpc("decline_join", params: memberParam(memberId)).execute().value }
    }

    public func unlinkMember(memberId: String) async throws(Failure) -> Member {
        try await run { try await client.rpc("unlink_member", params: memberParam(memberId)).execute().value }
    }

    public func sendInviteEmail(_ link: InviteLink) async throws(Failure) -> Bool {
        do {
            try await client.functions.invoke(
                "send-invites",
                options: FunctionInvokeOptions(body: [
                    "invite_id": link.inviteId, "token": link.token, "code": link.code,
                ])
            )
            return true
        } catch FunctionsError.httpError(let code, _) where code == 503 {
            // email_not_configured: the link still works, share it by hand.
            return false
        } catch {
            throw Failure(mapping: error)
        }
    }

    public func invites(kametiId: String) async throws(Failure) -> [Invite] {
        try await run {
            try await client.from("invites").select()
                .eq("kameti_id", value: kametiId).order("created_at", ascending: false).execute().value
        }
    }

    public func previewInvite(token: String?, inviteId: String?) async throws(Failure) -> InvitePreview {
        try await run {
            try await client.rpc("preview_invite", params: Params.inviteLookup(token: token, inviteId: inviteId))
                .execute().value
        }
    }

    public func acceptInvite(token: String?, inviteId: String?) async throws(Failure) -> Member {
        try await run {
            try await client.rpc("accept_invite", params: Params.inviteLookup(token: token, inviteId: inviteId))
                .execute().value
        }
    }

    public func declineInvite(token: String?, inviteId: String?) async throws(Failure) -> Member {
        try await run {
            try await client.rpc("decline_invite", params: Params.inviteLookup(token: token, inviteId: inviteId))
                .execute().value
        }
    }

    public func myInvitations() async throws(Failure) -> [MyInvitation] {
        try await run { try await client.rpc("list_my_invitations").execute().value }
    }
}
