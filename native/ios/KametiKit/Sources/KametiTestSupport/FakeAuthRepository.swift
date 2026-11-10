import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// An `AuthRepository` for tests and previews. Set what each sign-in returns,
/// then read `calls` to see what the code under test did.
public final class FakeAuthRepository: AuthRepository {
    private struct State {
        var userId: String?
        var continuations: [UUID: AsyncStream<String?>.Continuation] = [:]
        var google: Result<Bool, Failure> = .success(true)
        var apple: Result<Bool, Failure> = .success(true)
        var password: Result<Void, Failure> = .success(())
        var signOut: Result<Void, Failure> = .success(())
        var calls: [String] = []
    }

    /// `Mutex` can't be captured by closures; a class holding it can.
    private final class Box: Sendable {
        let mutex: Mutex<State>
        init(_ state: State) { mutex = Mutex(state) }
    }

    private let state: Box

    public init(userId: String? = nil) {
        state = Box(State(userId: userId))
    }

    // MARK: Configure

    public func setGoogle(_ result: Result<Bool, Failure>) { state.mutex.withLock { $0.google = result } }
    public func setApple(_ result: Result<Bool, Failure>) { state.mutex.withLock { $0.apple = result } }
    public func setPassword(_ result: Result<Void, Failure>) { state.mutex.withLock { $0.password = result } }
    public func setSignOut(_ result: Result<Void, Failure>) { state.mutex.withLock { $0.signOut = result } }

    /// Changes the signed-in user and tells every listener, as a real session would.
    public func emit(userId: String?) {
        let listeners = state.mutex.withLock { state -> [AsyncStream<String?>.Continuation] in
            state.userId = userId
            return Array(state.continuations.values)
        }
        for listener in listeners { listener.yield(userId) }
    }

    /// Everything called so far, for example `["google", "signOut"]`.
    public var calls: [String] { state.mutex.withLock { $0.calls } }

    // MARK: AuthRepository

    public var currentUserId: String? { state.mutex.withLock { $0.userId } }

    public func userIdChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let id = UUID()
            state.mutex.withLock { state in
                state.continuations[id] = continuation
                continuation.yield(state.userId)
            }
            continuation.onTermination = { [state] _ in
                state.mutex.withLock { $0.continuations[id] = nil }
            }
        }
    }

    public func signInWithGoogle() async throws(Failure) -> Bool {
        let result = state.mutex.withLock { state in state.calls.append("google"); return state.google }
        return try finish(result, user: "google-user")
    }

    public func signInWithApple() async throws(Failure) -> Bool {
        let result = state.mutex.withLock { state in state.calls.append("apple"); return state.apple }
        return try finish(result, user: "apple-user")
    }

    public func signInWithPassword(email: String, password: String) async throws(Failure) {
        let result = state.mutex.withLock { state in state.calls.append("password:\(email)"); return state.password }
        switch result {
        case .success: emit(userId: "password-user")
        case .failure(let failure): throw failure
        }
    }

    public func signOut() async throws(Failure) {
        let result = state.mutex.withLock { state in state.calls.append("signOut"); return state.signOut }
        switch result {
        case .success: emit(userId: nil)
        case .failure(let failure): throw failure
        }
    }

    private func finish(_ result: Result<Bool, Failure>, user: String) throws(Failure) -> Bool {
        switch result {
        case .success(let signedIn):
            if signedIn { emit(userId: user) }
            return signedIn
        case .failure(let failure):
            throw failure
        }
    }
}

/// A `ProfileRepository` for tests and previews.
public final class FakeProfileRepository: ProfileRepository {
    private let result: Mutex<Result<Profile, Failure>>
    private let loads: Mutex<[String]>

    public init(_ result: Result<Profile, Failure> = .success(Profile(id: "u1", displayName: "Hassan"))) {
        self.result = Mutex(result)
        loads = Mutex([])
    }

    public func set(_ newResult: Result<Profile, Failure>) { result.withLock { $0 = newResult } }
    /// The user ids that were loaded.
    public var loadedUserIds: [String] { loads.withLock { $0 } }

    public func myProfile(userId: String) async throws(Failure) -> Profile {
        loads.withLock { $0.append(userId) }
        return try result.withLock { $0 }.get()
    }
}
