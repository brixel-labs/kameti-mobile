import KametiCore
import KametiDomain
import Observation

/// The signed-in user's profile (name and how many kametis they run or are
/// in) and sign-out.
@MainActor
@Observable
public final class ProfileViewModel {
    public private(set) var profile: Profile?
    public private(set) var runningCount = 0
    public private(set) var memberCount = 0
    public private(set) var pastCount = 0
    public private(set) var peopleCount = 0
    public private(set) var failure: Failure?
    public private(set) var isLoading = false

    private let userId: String
    private let dependencies: KametiDependencies

    public init(userId: String, dependencies: KametiDependencies) {
        self.userId = userId
        self.dependencies = dependencies
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        failure = nil
        defer { isLoading = false }
        do throws(Failure) {
            let me = try await dependencies.profiles.myProfile(userId: userId)
            let all = try await dependencies.kametis.listKametis()
            self.profile = me
            runningCount = all.filter { $0.isOwned(by: userId) }.count
            memberCount = all.count - runningCount
            pastCount = all.filter { [.completed, .archived, .cancelled].contains($0.status) }.count
            peopleCount = (try? await dependencies.contacts.contacts().count) ?? 0
        } catch {
            failure = error
        }
    }

    /// The session store notices the signed-out state and the root view moves on.
    public func signOut() async {
        do throws(Failure) {
            try await dependencies.auth.signOut()
        } catch {
            failure = error
        }
    }
}
