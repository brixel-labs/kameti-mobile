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
    public private(set) var people: [Contact] = []
    public private(set) var pastKametis: [Kameti] = []
    public private(set) var signInMethods: [SignInMethod] = []
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
            pastKametis = all.filter { [.completed, .archived, .cancelled].contains($0.status) }
            pastCount = pastKametis.count
            people = ((try? await dependencies.contacts.contacts()) ?? [])
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            peopleCount = people.count
            signInMethods = await dependencies.auth.signInMethods()
        } catch {
            failure = error
        }
    }

    /// Saves the name other people see. Returns the failure to show, or `nil`.
    public func updateName(_ name: String) async -> Failure? {
        do throws(Failure) {
            profile = try await dependencies.profiles.updateDisplayName(userId: userId, name)
        } catch {
            return error
        }
        return nil
    }

    /// What deleting the account would do (it may be blocked).
    public func deletionCheck() async -> Result<AccountDeletionCheck, Failure> {
        do throws(Failure) { return .success(try await dependencies.account.deletionCheck()) } catch { return .failure(error) }
    }

    /// Deletes the account, then signs out; the root view moves on.
    public func deleteAccount() async -> Failure? {
        do throws(Failure) {
            try await dependencies.account.deleteAccount()
        } catch {
            return error
        }
        // The sign-in is gone on the server; clear it on the phone too.
        try? await dependencies.auth.signOut()
        return nil
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
