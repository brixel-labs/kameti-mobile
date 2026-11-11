import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// The owner's side of invites against the demo store: the App access state
/// of each member, sending, resending, revoking and "Invite all".
@MainActor
@Suite("Invite access")
struct InviteAccessTests {
    private func loaded() async -> (KametiDetailViewModel, () -> KametiDetailData?) {
        let model = KametiDetailViewModel(kametiId: "family", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        return (model, {
            if case .loaded(let data) = model.state { return data }
            return nil
        })
    }

    private func state(_ id: String, _ data: KametiDetailData) throws -> AccessState {
        AccessState.of(try #require(data.members.first { $0.id == id }), in: data)
    }

    @Test func eachMemberGetsTheRightState() async throws {
        let (_, data) = await loaded()
        let current = try #require(data())
        #expect(try state("f1", current) == .joined)
        #expect(try state("f5", current) == .needsApproval(invitedEmail: "hira.malik@gmail.com", acceptedEmail: "x7d2k9q4mb@privaterelay.appleid.com"))
        guard case .invited(let invite) = try state("f6", current) else { Issue.record("Faisal should be invited"); return }
        #expect(invite.email == "faisal.iqbal@gmail.com")
        #expect(try state("f3", current) == .joined)
        // Nobody left to invite: the rest have joined or have no email.
        #expect(AccessState.invitable(in: current).isEmpty)
    }

    @Test func sendingShowsTheCodeAndRevokingTakesItBack() async throws {
        let (model, data) = await loaded()
        #expect(await model.addMember(NewMember(name: "Zara Ahmed", email: "zara@x.com")) == nil)
        let zara = try #require(data()?.members.first { $0.name == "Zara Ahmed" })
        let afterAdd = try #require(data())
        #expect(AccessState.invitable(in: afterAdd).map(\.id) == [zara.id])

        #expect(await model.invite(memberId: zara.id) == nil)
        let sent = try #require(model.sentInvites[zara.id])
        #expect(sent.link.code.count == 6)
        #expect(sent.link.link.hasSuffix(sent.link.token))
        #expect(!sent.emailed) // email isn't set up in the demo
        let afterSend = try #require(data())
        guard case .invited = try state(zara.id, afterSend) else { Issue.record("should be invited"); return }

        // Sending again while one is live is refused; resending makes a new code.
        #expect(await model.invite(memberId: zara.id) == .server(code: "invite_already_pending", detail: nil))
        #expect(await model.invite(memberId: zara.id, resend: true) == nil)
        #expect(model.sentInvites[zara.id]?.link.inviteId != sent.link.inviteId)

        #expect(await model.revokeInvite(memberId: zara.id) == nil)
        #expect(model.sentInvites[zara.id] == nil)
        let afterRevoke = try #require(data())
        #expect(try state(zara.id, afterRevoke) == .notInvited(email: "zara@x.com", declined: false))
    }

    @Test func approvingAJoinFromTheMemberSheet() async throws {
        let (model, data) = await loaded()
        #expect(await model.approveJoin(memberId: "f5") == nil)
        let approved = try #require(data())
        #expect(try state("f5", approved) == .joined)
        #expect(await model.approveJoin(memberId: "f5") == .server(code: "not_pending_approval", detail: nil))
    }

    @Test func inviteAllInvitesEveryoneWithAnEmail() async throws {
        let (model, data) = await loaded()
        #expect(await model.addMember(NewMember(name: "A One", email: "a1@x.com")) == nil)
        #expect(await model.addMember(NewMember(name: "B Two", email: "b2@x.com")) == nil)
        #expect(await model.addMember(NewMember(name: "C Three")) == nil)
        let start = try #require(data())
        let people = AccessState.invitable(in: start)
        #expect(people.map(\.name) == ["A One", "B Two"])
        let result = await model.inviteAll(memberIds: people.map(\.id))
        #expect(result.invited == 2)
        #expect(result.failure == nil)
        let end = try #require(data())
        #expect(AccessState.invitable(in: end).isEmpty)
    }

    @Test func theOwnersOwnRowHasNoAccessCard() async throws {
        let model = KametiDetailViewModel(kametiId: "office", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        guard case .loaded(let data) = model.state else { Issue.record("not loaded"); return }
        let me = try #require(data.members.first { $0.profileId == SampleData.userId })
        #expect(AccessState.of(me, in: data) == .owner)
    }
}
