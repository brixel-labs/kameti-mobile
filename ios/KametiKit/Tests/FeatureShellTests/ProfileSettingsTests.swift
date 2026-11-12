import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureShell

/// Profile rows against the demo store: name, people, past kametis and
/// sign-in methods.
@MainActor
@Suite("Profile settings")
struct ProfileSettingsTests {
    @Test func loadsPeoplePastKametisAndSignInMethods() async {
        let model = ProfileViewModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        #expect(model.people.count == model.peopleCount)
        #expect(model.people.map(\.name) == model.people.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        #expect(model.pastKametis.map(\.id) == ["past-2025"])
        #expect(model.pastCount == 1)
        #expect(model.signInMethods == [SignInMethod(provider: .apple, email: "demo@kameti.test")])
    }

    @Test func renaming() async {
        let model = ProfileViewModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        #expect(await model.updateName("  Hassan Malik ") == nil)
        #expect(model.profile?.displayName == "Hassan Malik")
        #expect(await model.updateName("   ") == .server(code: "invalid_name", detail: nil))
        #expect(model.profile?.displayName == "Hassan Malik")
    }
}

/// Account deletion from Profile (REQUIREMENTS §5.5).
@MainActor
@Suite("Delete account")
struct DeleteAccountTests {
    /// An account repository that can be told to allow or refuse.
    private struct StubAccount: AccountRepository {
        let check: AccountDeletionCheck
        func deletionCheck() async throws(Failure) -> AccountDeletionCheck { check }
        func deleteAccount() async throws(Failure) {
            if !check.canDelete { throw Failure.server(code: "owner_has_active_kametis", detail: nil) }
        }
    }

    @Test func theDemoOwnerIsBlockedByRunningKametis() async throws {
        let model = ProfileViewModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        let check = try await model.deletionCheck().get()
        #expect(!check.canDelete)
        #expect(Set(check.blockingKametis.map(\.id)) == ["family", "friends"])
        #expect(check.draftsToDelete.map(\.id) == ["neighbours"])
        #expect(check.ownedKametisKept.map(\.id) == ["past-2025"])
        #expect(await model.deleteAccount() == .server(code: "owner_has_active_kametis", detail: nil))
    }

    @Test func aSuccessfulDeleteSignsOut() async {
        let auth = FakeAuthRepository(userId: "u1")
        var deps = SampleData.dependencies()
        deps.auth = auth
        deps.account = StubAccount(check: AccountDeletionCheck(canDelete: true, membershipsToUnlink: 2))
        let model = ProfileViewModel(userId: "u1", dependencies: deps)
        #expect(await model.deleteAccount() == nil)
        #expect(auth.currentUserId == nil)
    }

    @Test func theBackendCheckDecodes() throws {
        let json = #"{"can_delete":false,"blocking_kametis":[{"id":"k1","name":"Office","status":"active"}],"drafts_to_delete":[],"owned_kametis_kept":[],"memberships_to_unlink":3,"contacts_to_delete":12}"#
        let check = try KametiJSON.makeDecoder().decode(AccountDeletionCheck.self, from: Data(json.utf8))
        #expect(!check.canDelete)
        #expect(check.blockingKametis == [.init(id: "k1", name: "Office", status: .active)])
        #expect(check.membershipsToUnlink == 3)
        #expect(check.contactsToDelete == 12)
    }
}
