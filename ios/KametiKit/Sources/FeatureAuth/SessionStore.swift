import KametiCore
import KametiDomain
import Observation

/// Who is signed in. Follows the auth repository's stream, so a sign-in, a
/// sign-out and an expired session all end up here.
@MainActor
@Observable
public final class SessionStore {
    public enum State: Equatable, Sendable {
        /// Waiting for the first answer from the auth repository.
        case loading
        case signedOut
        case signedIn(userId: String)
    }

    public private(set) var state: State = .loading

    private let auth: any AuthRepository
    private var listener: Task<Void, Never>?

    public init(auth: any AuthRepository) {
        self.auth = auth
    }

    /// Starts following the session. Safe to call more than once.
    public func start() {
        guard listener == nil else { return }
        let changes = auth.userIdChanges()
        listener = Task { [weak self] in
            for await userId in changes {
                self?.state = userId.map { .signedIn(userId: $0) } ?? .signedOut
            }
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }
}
