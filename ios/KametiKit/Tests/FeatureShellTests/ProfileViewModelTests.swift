import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureShell

/// A dependencies bundle where only profile, kametis and auth matter.
@MainActor
private func makeDependencies(
    auth: FakeAuthRepository = FakeAuthRepository(userId: "u1"),
    profiles: FakeProfileRepository = FakeProfileRepository(),
    kametis: [Kameti] = []
) -> KametiDependencies {
    KametiDependencies(
        kametis: StubKametiRepository(kametis), ledger: UnusedRepositories(), payments: UnusedRepositories(),
        invites: UnusedRepositories(), audit: UnusedRepositories(), profiles: profiles,
        contacts: UnusedRepositories(), auth: auth
    )
}

private func kameti(_ id: String, owner: String) -> Kameti {
    Kameti(
        id: id, ownerId: owner, name: id, startMonth: DateOnly.make(year: 2026, month: 10), monthsN: 4,
        slotAmountC: Money(100_000), dueDay: 10, reminderDays: [1], maxSlotsPerMember: 4, status: .active
    )
}

@MainActor
@Suite("ProfileViewModel")
struct ProfileViewModelTests {
    @Test func loadsTheProfileAndCountsRoles() async {
        // Start from nothing saved on the phone (the cache outlives test runs).
        ProfileCache.clear(userId: "u1")
        let deps = makeDependencies(kametis: [kameti("a", owner: "u1"), kameti("b", owner: "u1"), kameti("c", owner: "u2")])
        let model = ProfileViewModel(userId: "u1", dependencies: deps)
        await model.load()
        #expect(model.profile?.displayName == "Hassan")
        #expect(model.runningCount == 2)
        #expect(model.memberCount == 1)
        #expect(model.failure == nil)
        #expect(!model.isLoading)
    }

    @Test func aFailedLoadIsReportedAndCanBeRetried() async {
        // Its own user with nothing saved on the phone: the profile cache is
        // shared (UserDefaults), and another test caches u1's profile.
        ProfileCache.clear(userId: "u-retry")
        defer { ProfileCache.clear(userId: "u-retry") }
        let profiles = FakeProfileRepository(.failure(.network))
        let model = ProfileViewModel(
            userId: "u-retry", dependencies: makeDependencies(auth: FakeAuthRepository(userId: "u-retry"), profiles: profiles)
        )
        await model.load()
        #expect(model.failure == .network)
        #expect(model.profile == nil)

        profiles.set(.success(Profile(id: "u1", displayName: "Hassan")))
        await model.load()
        #expect(model.failure == nil)
        #expect(model.profile != nil)
    }

    @Test func signOutCallsTheAuthRepository() async {
        let auth = FakeAuthRepository(userId: "u1")
        let model = ProfileViewModel(userId: "u1", dependencies: makeDependencies(auth: auth))
        await model.signOut()
        #expect(auth.calls == ["signOut"])
        #expect(auth.currentUserId == nil)
    }

    @Test func aFailedSignOutIsReported() async {
        let auth = FakeAuthRepository(userId: "u1")
        auth.setSignOut(.failure(.network))
        let model = ProfileViewModel(userId: "u1", dependencies: makeDependencies(auth: auth))
        await model.signOut()
        #expect(model.failure == .network)
        #expect(auth.currentUserId == "u1")
    }
}
