import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// The demo's invites, mirroring the backend's invite RPCs closely enough to
/// try every screen: sending, resending and revoking (owner), approving a
/// join, and accepting or declining an invite addressed to the demo account.
/// Email is never "configured" here, so codes and links are shared by hand.
final class SampleInvitesRepository: InvitesRepository {
    private struct Secret { let token: String; let code: String }
    private struct State {
        var invites: [Invite]
        var secrets: [String: Secret]
        var counter = 0
    }

    private let kametis: SampleKametiRepository
    private let contacts: SampleContactStore
    private let log: SampleAuditLog
    private let state: Mutex<State>

    init(kametis: SampleKametiRepository, contacts: SampleContactStore, log: SampleAuditLog = SampleAuditLog()) {
        self.kametis = kametis
        self.contacts = contacts
        self.log = log
        let day: TimeInterval = 86_400
        let now = SampleData.now
        state = Mutex(State(
            invites: [
                // Faisal: invited two days ago; the email bounced (E39b).
                Invite(id: "inv-f6", kametiId: "family", memberId: "f6", status: .pending, expiresAt: now + 12 * day, sendCount: 1,
                       email: "faisal.iqbal@gmail.com", sentAt: now - 2 * day, deliveryStatus: .bounced),
                // Hira: accepted with a different (Apple private relay) email.
                Invite(id: "inv-f5", kametiId: "family", memberId: "f5", status: .accepted, expiresAt: now + 13 * day, sendCount: 1,
                       email: "hira.malik@gmail.com", sentAt: now - 1 * day, acceptedEmail: "x7d2k9q4mb@privaterelay.appleid.com"),
                // An invite to the demo account itself.
                Invite(id: "inv-cz3", kametiId: "cousins", memberId: "cz3", status: .pending, expiresAt: now + 14 * day, sendCount: 1,
                       email: SampleData.email, sentAt: now - 3600),
            ],
            secrets: ["inv-cz3": Secret(token: "demo-cousins-invite-token-000000", code: "CZN7QK")]
        ))
    }

    private static let base = "https://www.fhbtechservices.com/kameti/join/"

    // MARK: Owner

    func createInvite(memberId: String) async throws(Failure) -> InviteLink {
        guard let member = kametis.memberRow(memberId) else { throw Failure.server(code: "not_found", detail: nil) }
        if member.joinStatus == .joined || member.profileId != nil { throw Failure.server(code: "member_already_joined", detail: nil) }
        if member.joinStatus == .pendingApproval { throw Failure.server(code: "approval_pending", detail: nil) }
        guard let email = contacts.contact(id: member.contactId)?.email else { throw Failure.server(code: "member_has_no_email", detail: nil) }
        if state.withLock({ $0.invites.contains { $0.memberId == memberId && $0.status == .pending } }) {
            throw Failure.server(code: "invite_already_pending", detail: nil)
        }
        return issue(member: member, email: email, sendCount: 1)
    }

    func resendInvite(memberId: String) async throws(Failure) -> InviteLink {
        guard let member = kametis.memberRow(memberId) else { throw Failure.server(code: "not_found", detail: nil) }
        if member.joinStatus == .pendingApproval { throw Failure.server(code: "approval_pending", detail: nil) }
        if member.joinStatus == .joined { throw Failure.server(code: "member_already_joined", detail: nil) }
        let previous = state.withLock { s in s.invites.filter { $0.memberId == memberId }.last }
        guard let previous else { throw Failure.server(code: "no_invite", detail: nil) }
        let email = contacts.contact(id: member.contactId)?.email ?? previous.email ?? ""
        guard !email.isEmpty else { throw Failure.server(code: "member_has_no_email", detail: nil) }
        state.withLock { s in
            for index in s.invites.indices where s.invites[index].memberId == memberId && s.invites[index].status == .pending {
                s.invites[index] = replaced(s.invites[index], status: .superseded)
            }
        }
        return issue(member: member, email: email, sendCount: previous.sendCount + 1)
    }

    func revokeInvite(memberId: String) async throws(Failure) -> Member {
        let found = state.withLock { s -> Bool in
            guard let index = s.invites.firstIndex(where: { $0.memberId == memberId && $0.status == .pending }) else { return false }
            s.invites[index] = replaced(s.invites[index], status: .revoked)
            return true
        }
        guard found else { throw Failure.server(code: "no_pending_invite", detail: nil) }
        let member = try required(kametis.setJoin(memberId: memberId, status: .notInvited, profileId: nil))
        log.record(member.kametiId, "invite.revoke", entity: "invite", entityId: nil, member: memberId)
        return member
    }

    func approveJoin(memberId: String) async throws(Failure) -> Member {
        guard kametis.memberRow(memberId)?.joinStatus == .pendingApproval else { throw Failure.server(code: "not_pending_approval", detail: nil) }
        let profile = kametis.memberRow(memberId)?.profileId
        let member = try required(kametis.setJoin(memberId: memberId, status: .joined, profileId: profile))
        log.record(member.kametiId, "member.approve_join", entity: "member", entityId: memberId, member: memberId)
        return member
    }

    func declineJoin(memberId: String) async throws(Failure) -> Member {
        guard kametis.memberRow(memberId)?.joinStatus == .pendingApproval else { throw Failure.server(code: "not_pending_approval", detail: nil) }
        let member = try required(kametis.setJoin(memberId: memberId, status: .declined, profileId: nil))
        log.record(member.kametiId, "member.decline_join", entity: "member", entityId: memberId, member: memberId)
        return member
    }

    func unlinkMember(memberId: String) async throws(Failure) -> Member {
        guard let member = kametis.memberRow(memberId), member.profileId != nil else { throw Failure.server(code: "member_not_linked", detail: nil) }
        if member.profileId == SampleData.userId { throw Failure.server(code: "cannot_unlink_owner", detail: nil) }
        return try required(kametis.setJoin(memberId: memberId, status: .notInvited, profileId: nil))
    }

    /// Email isn't set up in the demo: the owner shares the code or link.
    func sendInviteEmail(_ link: InviteLink) async throws(Failure) -> Bool { false }

    func invites(kametiId: String) async throws(Failure) -> [Invite] {
        state.withLock { s in s.invites.filter { $0.kametiId == kametiId }.reversed() }
    }

    // MARK: Invitee

    func previewInvite(token: String?, inviteId: String?) async throws(Failure) -> InvitePreview {
        let invite = try find(token: token, inviteId: inviteId, live: false)
        guard let kameti = kametis.kametiRow(invite.kametiId), let member = kametis.memberRow(invite.memberId) else {
            throw Failure.server(code: "invite_not_found", detail: nil)
        }
        let shares = kametis.shareRows(memberId: member.id, kametiId: kameti.id).compactMap { row in
            row.slot.map { InviteShare(payoutMonthIndex: $0.payoutMonthIndex, monthlyAmount: row.share.monthlyAmount) }
        }.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }
        return InvitePreview(
            inviteId: invite.id, status: invite.status.rawValue, expired: invite.isExpired(at: SampleData.now), expiresAt: invite.expiresAt,
            emailMatches: invite.email?.lowercased() == SampleData.email, kametiName: kameti.name,
            ownerName: SampleData.ownerNames[kameti.ownerId] ?? "", memberName: member.name, shares: shares,
            startMonth: kameti.startMonth, monthsN: kameti.monthsN
        )
    }

    func acceptInvite(token: String?, inviteId: String?) async throws(Failure) -> Member {
        let invite = try find(token: token, inviteId: inviteId, live: true)
        guard let kameti = kametis.kametiRow(invite.kametiId), [.draft, .active].contains(kameti.status) else {
            throw Failure.server(code: "kameti_not_joinable", detail: nil)
        }
        if kameti.ownerId == SampleData.userId { throw Failure.server(code: "owner_cannot_join", detail: nil) }
        guard let member = kametis.memberRow(invite.memberId), member.profileId == nil,
              ![.joined, .pendingApproval].contains(member.joinStatus) else {
            throw Failure.server(code: "member_already_linked", detail: nil)
        }
        let matches = invite.email?.lowercased() == SampleData.email
        state.withLock { s in
            if let index = s.invites.firstIndex(where: { $0.id == invite.id }) {
                s.invites[index] = replaced(s.invites[index], status: .accepted, acceptedEmail: SampleData.email)
            }
        }
        return try required(kametis.setJoin(memberId: member.id, status: matches ? .joined : .pendingApproval, profileId: SampleData.userId))
    }

    func declineInvite(token: String?, inviteId: String?) async throws(Failure) -> Member {
        let invite = try find(token: token, inviteId: inviteId, live: true)
        state.withLock { s in
            if let index = s.invites.firstIndex(where: { $0.id == invite.id }) { s.invites[index] = replaced(s.invites[index], status: .declined) }
        }
        return try required(kametis.setJoin(memberId: invite.memberId, status: .declined, profileId: nil))
    }

    func myInvitations() async throws(Failure) -> [MyInvitation] {
        let live = state.withLock { s in
            s.invites.filter { $0.status == .pending && !$0.isExpired(at: SampleData.now) && $0.email?.lowercased() == SampleData.email }
        }
        return live.compactMap { invite in
            guard let kameti = kametis.kametiRow(invite.kametiId), let member = kametis.memberRow(invite.memberId) else { return nil }
            return MyInvitation(
                inviteId: invite.id, kametiName: kameti.name, ownerName: SampleData.ownerNames[kameti.ownerId] ?? "",
                memberName: member.name, expiresAt: invite.expiresAt, createdAt: invite.sentAt ?? SampleData.now
            )
        }
    }

    // MARK: Helpers

    private func issue(member: Member, email: String, sendCount: Int) -> InviteLink {
        let created = state.withLock { s -> (Invite, Secret) in
            s.counter += 1
            let id = "inv-new-\(s.counter)"
            let secret = Secret(token: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(), code: Self.randomCode())
            let invite = Invite(
                id: id, kametiId: member.kametiId, memberId: member.id, status: .pending, expiresAt: SampleData.now + 14 * 86_400,
                sendCount: sendCount, email: email, sentAt: SampleData.now
            )
            s.invites.append(invite)
            s.secrets[id] = secret
            return (invite, secret)
        }
        kametis.setJoin(memberId: member.id, status: .invited, profileId: nil)
        log.record(member.kametiId, "invite.create", entity: "invite", entityId: created.0.id, member: member.id,
                   after: .object(["member_id": .string(member.id), "email": .string(email)]))
        return InviteLink(
            inviteId: created.0.id, memberId: member.id, token: created.1.token, code: created.1.code,
            link: Self.base + created.1.token, expiresAt: created.0.expiresAt, email: email
        )
    }

    /// Like `private.find_invite`: by id (my email only), by a short code, or by token.
    private func find(token: String?, inviteId: String?, live: Bool) throws(Failure) -> Invite {
        let text = (token ?? "").trimmingCharacters(in: .whitespaces)
        guard text.isEmpty != (inviteId == nil) else { throw Failure.server(code: "invalid_invite", detail: nil) }
        let invite: Invite? = state.withLock { s in
            if let inviteId { return s.invites.first { $0.id == inviteId && $0.email?.lowercased() == SampleData.email } }
            if text.count <= 8 {
                return s.invites.first { s.secrets[$0.id]?.code == text.uppercased() && $0.status == .pending }
            }
            return s.invites.first { s.secrets[$0.id]?.token == text }
        }
        guard let invite else { throw Failure.server(code: "invite_not_found", detail: nil) }
        if live {
            if invite.status != .pending { throw Failure.server(code: "invite_not_active", detail: nil) }
            if invite.isExpired(at: SampleData.now) { throw Failure.server(code: "invite_expired", detail: nil) }
        }
        return invite
    }

    private func replaced(_ old: Invite, status: InviteStatus, acceptedEmail: String? = nil) -> Invite {
        Invite(
            id: old.id, kametiId: old.kametiId, memberId: old.memberId, status: status, expiresAt: old.expiresAt,
            sendCount: old.sendCount, email: old.email, sentAt: old.sentAt, acceptedEmail: acceptedEmail ?? old.acceptedEmail,
            deliveryStatus: old.deliveryStatus
        )
    }

    private func required(_ member: Member?) throws(Failure) -> Member {
        guard let member else { throw Failure.server(code: "not_found", detail: nil) }
        return member
    }

    private static func randomCode() -> String {
        // No 0/O or 1/I, so a code read aloud can't be misheard.
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in letters.randomElement() ?? "K" })
    }
}
