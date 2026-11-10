import Auth
import Foundation
import KametiCore
import KametiDomain
import Supabase

/// What a social provider hands back after the user picks an account.
public struct ProviderCredential: Sendable, Equatable {
    public let idToken: String
    public let accessToken: String?
    /// The raw nonce whose hash the provider put in the token (Apple).
    public let nonce: String?

    public init(idToken: String, accessToken: String? = nil, nonce: String? = nil) {
        self.idToken = idToken; self.accessToken = accessToken; self.nonce = nonce
    }
}

/// Shows a provider's sign-in sheet and returns its credential, `nil` when
/// the user closes it. The app target implements this with the Google SDK
/// and AuthenticationServices, so this module links neither.
public protocol ProviderCredentialSource: Sendable {
    func credential() async throws(Failure) -> ProviderCredential?
}

public final class SupabaseAuthRepository: AuthRepository {
    private let client: SupabaseClient
    private let google: (any ProviderCredentialSource)?
    private let apple: (any ProviderCredentialSource)?

    public init(
        client: SupabaseClient,
        google: (any ProviderCredentialSource)? = nil,
        apple: (any ProviderCredentialSource)? = nil
    ) {
        self.client = client; self.google = google; self.apple = apple
    }

    public var currentUserId: String? { client.auth.currentUser?.id.uuidString.lowercased() }

    public func userIdChanges() -> AsyncStream<String?> {
        let changes = client.auth.authStateChanges
        return AsyncStream { continuation in
            let task = Task {
                for await (_, session) in changes {
                    continuation.yield(session?.user.id.uuidString.lowercased())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func signInWithGoogle() async throws(Failure) -> Bool {
        try await signIn(with: google, provider: .google)
    }

    public func signInWithApple() async throws(Failure) -> Bool {
        try await signIn(with: apple, provider: .apple)
    }

    private func signIn(with source: (any ProviderCredentialSource)?, provider: OpenIDConnectCredentials.Provider) async throws(Failure) -> Bool {
        guard let source else { throw Failure.signIn(.misconfigured, detail: "no credential source for \(provider)") }
        guard let credential = try await source.credential() else { return false }
        do {
            try await client.auth.signInWithIdToken(credentials: OpenIDConnectCredentials(
                provider: provider, idToken: credential.idToken,
                accessToken: credential.accessToken, nonce: credential.nonce
            ))
            return true
        } catch {
            throw Self.signInFailure(error)
        }
    }

    public func signInWithPassword(email: String, password: String) async throws(Failure) {
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            throw Self.signInFailure(error)
        }
    }

    public func signOut() async throws(Failure) {
        try await run { try await client.auth.signOut() }
    }

    /// A refused sign-in says why; a network problem still says "offline".
    static func signInFailure(_ error: any Error) -> Failure {
        let failure = Failure(mapping: error)
        switch failure {
        case .auth(let message): return .signIn(.rejected, detail: message)
        case .network, .signIn: return failure
        default: return .signIn(.rejected, detail: String(describing: error))
        }
    }
}
