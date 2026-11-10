import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureAuth

@MainActor
@Suite("SessionStore")
struct SessionStoreTests {
    /// Lets the store's listener task run.
    private func settle() async { for _ in 0..<5 { await Task.yield() } }

    @Test func startsLoadingThenFollowsTheAuthStream() async {
        let auth = FakeAuthRepository()
        let store = SessionStore(auth: auth)
        #expect(store.state == .loading)

        store.start()
        await settle()
        #expect(store.state == .signedOut)

        auth.emit(userId: "u1")
        await settle()
        #expect(store.state == .signedIn(userId: "u1"))

        auth.emit(userId: nil)
        await settle()
        #expect(store.state == .signedOut)
        store.stop()
    }

    @Test func anExistingSessionIsPickedUpAtStart() async {
        let store = SessionStore(auth: FakeAuthRepository(userId: "u9"))
        store.start()
        await settle()
        #expect(store.state == .signedIn(userId: "u9"))
        store.stop()
    }

    @Test func startingTwiceKeepsOneListener() async {
        let auth = FakeAuthRepository()
        let store = SessionStore(auth: auth)
        store.start()
        store.start()
        await settle()
        auth.emit(userId: "u1")
        await settle()
        #expect(store.state == .signedIn(userId: "u1"))
        store.stop()
    }
}

@MainActor
@Suite("SignInViewModel")
struct SignInViewModelTests {
    @Test func aSuccessfulSignInLeavesNoFailureAndNoSpinner() async {
        let auth = FakeAuthRepository()
        let model = SignInViewModel(auth: auth)
        await model.signIn(with: .google)
        #expect(auth.calls == ["google"])
        #expect(model.failure == nil)
        #expect(model.busyProvider == nil)
        #expect(auth.currentUserId == "google-user")
    }

    @Test func closingTheSheetIsNotAnError() async {
        let auth = FakeAuthRepository()
        auth.setApple(.success(false))
        let model = SignInViewModel(auth: auth)
        await model.signIn(with: .apple)
        #expect(model.failure == nil)
        #expect(auth.currentUserId == nil)
    }

    @Test func aFailureIsKeptAndTheSpinnerStops() async {
        let auth = FakeAuthRepository()
        auth.setGoogle(.failure(.signIn(.misconfigured, detail: "Unacceptable audience in id_token")))
        let model = SignInViewModel(auth: auth)
        await model.signIn(with: .google)
        #expect(model.failure == .signIn(.misconfigured, detail: "Unacceptable audience in id_token"))
        #expect(model.busyProvider == nil)
        #expect(auth.currentUserId == nil)
    }

    @Test func aRetryClearsTheEarlierFailure() async {
        let auth = FakeAuthRepository()
        auth.setGoogle(.failure(.network))
        let model = SignInViewModel(auth: auth)
        await model.signIn(with: .google)
        #expect(model.failure == .network)
        auth.setGoogle(.success(true))
        await model.signIn(with: .google)
        #expect(model.failure == nil)
    }

    @Test func devAccountsSignInWithTheirSeededEmail() async {
        let auth = FakeAuthRepository()
        let model = SignInViewModel(auth: auth, showsDevSignIn: true)
        await model.signIn(as: .member)
        #expect(auth.calls == ["password:member@kameti.test"])
        #expect(model.showsDevSignIn)
        #expect(auth.currentUserId == "password-user")
    }

    @Test func aDevSignInFailureIsReported() async {
        let auth = FakeAuthRepository()
        auth.setPassword(.failure(.signIn(.rejected, detail: "Invalid login credentials")))
        let model = SignInViewModel(auth: auth, showsDevSignIn: true)
        await model.signIn(as: .owner)
        #expect(model.failure == .signIn(.rejected, detail: "Invalid login credentials"))
    }
}
