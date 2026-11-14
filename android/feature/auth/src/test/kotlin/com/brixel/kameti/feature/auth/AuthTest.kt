package com.brixel.kameti.feature.auth

import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.SignInProblem
import com.brixel.kameti.testsupport.FakeAuthRepository
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class SessionStoreTest {
    @Test
    fun startsLoadingThenFollowsTheAuthStream() = runTest(UnconfinedTestDispatcher()) {
        val auth = FakeAuthRepository()
        val store = SessionStore(auth, backgroundScope)
        assertEquals(SessionStore.State.Loading, store.state.value)

        store.start()
        assertEquals(SessionStore.State.SignedOut, store.state.value)

        auth.emit("u1")
        assertEquals(SessionStore.State.SignedIn("u1"), store.state.value)

        auth.emit(null)
        assertEquals(SessionStore.State.SignedOut, store.state.value)
        store.stop()
    }

    @Test
    fun anExistingSessionIsPickedUpAtStart() = runTest(UnconfinedTestDispatcher()) {
        val store = SessionStore(FakeAuthRepository("u9"), backgroundScope)
        store.start()
        assertEquals(SessionStore.State.SignedIn("u9"), store.state.value)
        store.stop()
    }

    @Test
    fun startingTwiceKeepsOneListener() = runTest(UnconfinedTestDispatcher()) {
        val auth = FakeAuthRepository()
        val store = SessionStore(auth, backgroundScope)
        store.start()
        store.start()
        auth.emit("u1")
        assertEquals(SessionStore.State.SignedIn("u1"), store.state.value)
        store.stop()
    }

    @Test
    fun aStoppedStoreNoLongerFollows() = runTest(UnconfinedTestDispatcher()) {
        val auth = FakeAuthRepository("u1")
        val store = SessionStore(auth, backgroundScope)
        store.start()
        store.stop()
        auth.emit(null)
        assertEquals(SessionStore.State.SignedIn("u1"), store.state.value)
    }
}

class SignInViewModelTest {
    @Test
    fun aSuccessfulSignInLeavesNoFailureAndNoSpinner() = runTest {
        val auth = FakeAuthRepository()
        val model = SignInViewModel(auth)
        model.signIn(SignInProvider.Google)
        assertEquals(listOf("google"), auth.calls)
        assertNull(model.state.value.failure)
        assertNull(model.state.value.busyProvider)
        assertEquals("google-user", auth.currentUserId)
    }

    @Test
    fun closingTheSheetIsNotAnError() = runTest {
        val auth = FakeAuthRepository()
        auth.setGoogle(Attempt.Success(false))
        val model = SignInViewModel(auth)
        model.signIn(SignInProvider.Google)
        assertNull(model.state.value.failure)
        assertNull(auth.currentUserId)
    }

    @Test
    fun aFailureIsKeptAndTheSpinnerStops() = runTest {
        val auth = FakeAuthRepository()
        val refused = Failure.SignIn(SignInProblem.Misconfigured, "Unacceptable audience in id_token")
        auth.setGoogle(Attempt.Failed(refused))
        val model = SignInViewModel(auth)
        model.signIn(SignInProvider.Google)
        assertEquals(refused, model.state.value.failure)
        assertNull(model.state.value.busyProvider)
        assertNull(auth.currentUserId)
    }

    @Test
    fun aRetryClearsTheEarlierFailure() = runTest {
        val auth = FakeAuthRepository()
        auth.setGoogle(Attempt.Failed(Failure.Network))
        val model = SignInViewModel(auth)
        model.signIn(SignInProvider.Google)
        assertEquals(Failure.Network, model.state.value.failure)
        auth.setGoogle(Attempt.Success(true))
        model.signIn(SignInProvider.Google)
        assertNull(model.state.value.failure)
    }

    @Test
    fun devAccountsSignInWithTheirSeededEmail() = runTest {
        val auth = FakeAuthRepository()
        val model = SignInViewModel(auth, showsDevSignIn = true)
        model.signIn(DevAccount.Member)
        assertEquals(listOf("password:member@kameti.test"), auth.calls)
        assertTrue(model.showsDevSignIn)
        assertEquals("password-user", auth.currentUserId)
    }

    @Test
    fun aDevSignInFailureIsReported() = runTest {
        val auth = FakeAuthRepository()
        val refused = Failure.SignIn(SignInProblem.Rejected, "Invalid login credentials")
        auth.setPassword(Attempt.Failed(refused))
        val model = SignInViewModel(auth, showsDevSignIn = true)
        model.signIn(DevAccount.Owner)
        assertEquals(refused, model.state.value.failure)
    }
}
