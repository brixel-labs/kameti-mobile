import KametiCore
import KametiDomain
import Observation

/// Seeded test accounts of the LOCAL Supabase (`kameti-backend/supabase/seed.sql`).
/// They never exist in kameti-prod, and their buttons only show in a dev
/// build that has a backend.
public enum DevAccount: Sendable, CaseIterable {
    case owner, member

    public var email: String {
        switch self {
        case .owner: "owner@kameti.test"
        case .member: "member@kameti.test"
        }
    }

    static let password = "kameti-dev-pass"
}

/// Drives the sign-in screen. A cancelled sheet is not an error; every real
/// failure becomes a `Failure` the view turns into a message.
@MainActor
@Observable
public final class SignInViewModel {
    public enum Provider: Sendable { case apple, google }

    public private(set) var busyProvider: Provider?
    public private(set) var busyDevAccount: DevAccount?
    public private(set) var failure: Failure?
    public let showsDevSignIn: Bool

    private let auth: any AuthRepository

    public init(auth: any AuthRepository, showsDevSignIn: Bool = false) {
        self.auth = auth
        self.showsDevSignIn = showsDevSignIn
    }

    public var isBusy: Bool { busyProvider != nil || busyDevAccount != nil }

    /// On success the session store sees the new user and the root view moves on.
    public func signIn(with provider: Provider) async {
        guard !isBusy else { return }
        busyProvider = provider
        failure = nil
        defer { busyProvider = nil }
        do throws(Failure) {
            switch provider {
            case .apple: _ = try await auth.signInWithApple()
            case .google: _ = try await auth.signInWithGoogle()
            }
        } catch {
            failure = error
        }
    }

    public func signIn(as account: DevAccount) async {
        guard !isBusy else { return }
        busyDevAccount = account
        failure = nil
        defer { busyDevAccount = nil }
        do throws(Failure) {
            try await auth.signInWithPassword(email: account.email, password: DevAccount.password)
        } catch {
            failure = error
        }
    }
}
