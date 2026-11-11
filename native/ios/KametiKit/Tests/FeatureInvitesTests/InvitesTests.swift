import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureInvites

@Suite("InviteLogic")
struct InviteLogicTests {
    private let now = DateOnly.make(year: 2026, month: 11, day: 10)

    @Test func expiryReadsInDays() {
        #expect(InviteLogic.expiryText(now + 12 * 86_400 + 60, now: now) == "Expires in 12 days")
        #expect(InviteLogic.expiryText(now + 86_400 + 60, now: now) == "Expires tomorrow")
        #expect(InviteLogic.expiryText(now + 3600, now: now) == "Expires today")
        #expect(InviteLogic.expiryText(now - 1, now: now) == "Expired")
    }

    @Test func turnsAndMonthlyTotal() {
        let shares = [InviteShare(payoutMonthIndex: 4, monthlyAmount: Money(50_000)), InviteShare(payoutMonthIndex: 2, monthlyAmount: Money(75_000))]
        #expect(InviteLogic.monthlyTotal(shares) == Money(125_000))
        #expect(InviteLogic.turnsText(shares) == "Months 2 and 4")
        #expect(InviteLogic.turnsText([shares[0]]) == "Month 4")
        #expect(InviteLogic.turnsText([]) == nil)
    }

    @Test func turnsShowTheMonthAndYear() {
        let start = DateOnly.make(year: 2026, month: 11)
        let third = [InviteShare(payoutMonthIndex: 3, monthlyAmount: Money(200_000))]
        #expect(InviteLogic.turnsText(third, startMonth: start) == "January 2027 · Month 3")
        let two = third + [InviteShare(payoutMonthIndex: 1, monthlyAmount: Money(50_000))]
        #expect(InviteLogic.turnsText(two, startMonth: start) == "Nov 2026 and Jan 2027")
        #expect(InviteLogic.runsText(startMonth: start, monthsN: 4) == "Nov 2026 → Feb 2027")
        #expect(InviteLogic.payout(two, monthsN: 4) == Money(1_000_000))
    }

    @Test func initialsAndMasking() {
        #expect(InviteLogic.initials("Ayesha Siddiqui Khan") == "AS")
        #expect(InviteLogic.masked("x7d2k9q4mb@privaterelay.appleid.com") == "x7••••••••@privaterelay.appleid.com")
        #expect(InviteLogic.masked("ab@x.com") == "ab•••@x.com")
    }
}

/// Accepting, declining and approving against the demo store, which mirrors
/// the backend's invite RPCs.
@MainActor
@Suite("Joining")
struct JoiningTests {
    @Test func acceptingByIdJoinsAndShowsTheKameti() async throws {
        let dependencies = SampleData.dependencies()
        let before = try await dependencies.kametis.listKametis()
        #expect(!before.contains { $0.id == "cousins" })
        let model = JoinInviteViewModel(token: nil, inviteId: "inv-cz3", dependencies: dependencies)
        await model.load()
        guard case .loaded(let preview) = model.state else { Issue.record("not loaded"); return }
        #expect(preview.kametiName == "Cousins kameti")
        #expect(preview.ownerName == "Ayesha Siddiqui")
        #expect(preview.emailMatches)
        #expect(InviteLogic.monthlyTotal(preview.shares) == Money(200_000))
        #expect(await model.accept() == "cousins")
        let after = try await dependencies.kametis.listKametis()
        #expect(after.contains { $0.id == "cousins" })
        let left = try await dependencies.invites.myInvitations()
        #expect(left.isEmpty)
    }

    @Test func aCodeWorksInAnyCase() async {
        let model = JoinInviteViewModel(token: " czn7qk ", inviteId: nil, dependencies: SampleData.dependencies())
        await model.load()
        guard case .loaded(let preview) = model.state else { Issue.record("not loaded"); return }
        #expect(preview.isOpen)
    }

    @Test func aWrongCodeFails() async {
        let model = JoinInviteViewModel(token: "ZZZZZZ", inviteId: nil, dependencies: SampleData.dependencies())
        await model.load()
        #expect(model.state == .failed(.server(code: "invite_not_found", detail: nil)))
    }

    @Test func decliningRemovesTheInvitation() async throws {
        let dependencies = SampleData.dependencies()
        let model = JoinInviteViewModel(token: nil, inviteId: "inv-cz3", dependencies: dependencies)
        await model.load()
        await model.decline()
        #expect(model.state == .declined(kametiName: "Cousins kameti"))
        let left = try await dependencies.invites.myInvitations()
        #expect(left.isEmpty)
        // A declined invite can't be accepted any more.
        #expect(await model.accept() == nil)
    }

    @Test func inboxListsInvitationsAndJoinRequests() async throws {
        let dependencies = SampleData.dependencies()
        let inbox = InboxViewModel(userId: SampleData.userId, dependencies: dependencies)
        await inbox.load()
        #expect(inbox.invitations.map(\.inviteId) == ["inv-cz3"])
        let request = try #require(inbox.requests.first)
        #expect(request.member.name == "Hira Malik")
        #expect(request.invitedEmail == "hira.malik@gmail.com")
        #expect(request.acceptedEmail?.hasSuffix("privaterelay.appleid.com") == true)
        #expect(await inbox.approve(request) == nil)
        #expect(inbox.requests.isEmpty)
        let family = try await dependencies.kametis.members(kametiId: "family")
        #expect(family.first { $0.id == "f5" }?.joinStatus == .joined)
    }

    @Test func rejectingAJoinRequestDeclinesTheMember() async throws {
        let dependencies = SampleData.dependencies()
        let inbox = InboxViewModel(userId: SampleData.userId, dependencies: dependencies)
        await inbox.load()
        let request = try #require(inbox.requests.first)
        #expect(await inbox.reject(request) == nil)
        let family = try await dependencies.kametis.members(kametiId: "family")
        let hira = try #require(family.first { $0.id == "f5" })
        #expect(hira.joinStatus == .declined)
        #expect(hira.profileId == nil)
    }
}

/// E39: an account already in the kameti is told up front and gets no Join button.
@Suite("Invite preview blockers")
struct InvitePreviewBlockerTests {
    private func preview(alreadyMember: Bool? = nil, name: String? = nil, isOwner: Bool? = nil) -> InvitePreview {
        InvitePreview(
            inviteId: "i", status: "pending", expired: false, expiresAt: .distantFuture, emailMatches: false,
            kametiName: "Demo Office Kameti", ownerName: "Demo Owner", memberName: "Muhammad Hassan",
            alreadyMember: alreadyMember, alreadyMemberName: name, isOwner: isOwner
        )
    }

    @Test func alreadyAMemberCantJoin() {
        let p = preview(alreadyMember: true, name: "Demo Member")
        #expect(!p.canJoin)
        #expect(InviteLogic.blockedReason(p)?.contains("Demo Member") == true)
    }

    @Test func theOwnerCantJoin() {
        let p = preview(isOwner: true)
        #expect(!p.canJoin)
        #expect(InviteLogic.blockedReason(p) != nil)
    }

    @Test func anOlderBackendStillAllowsJoining() {
        let p = preview()
        #expect(p.canJoin)
        #expect(InviteLogic.blockedReason(p) == nil)
    }

    @Test func decodesTheNewFields() throws {
        let json = #"{"invite_id":"i","status":"pending","expired":false,"expires_at":"2026-12-01T00:00:00Z","email_matches":false,"kameti_name":"K","owner_name":"O","member_name":"M","shares":[],"already_member":true,"already_member_name":"Demo Member","is_owner":false}"#
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(InvitePreview.self, from: Data(json.utf8))
        #expect(p.alreadyMember == true && p.alreadyMemberName == "Demo Member" && p.isOwner == false)
    }
}

