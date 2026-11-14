package com.brixel.kameti.feature.shell

import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.AccountDeletionCheck
import com.brixel.kameti.domain.AccountRepository
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.domain.SignInMethod
import com.brixel.kameti.testsupport.FakeAuthRepository
import com.brixel.kameti.testsupport.FakeProfileRepository
import com.brixel.kameti.testsupport.SampleData
import com.brixel.kameti.testsupport.StubKametiRepository
import com.brixel.kameti.testsupport.UnusedRepositories
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest

/** A dependencies bundle where only profile, kametis and auth matter. */
private fun makeDependencies(
    auth: FakeAuthRepository = FakeAuthRepository("u1"),
    profiles: FakeProfileRepository = FakeProfileRepository(),
    kametis: List<Kameti> = emptyList(),
): KametiDependencies {
    val unused = UnusedRepositories()
    return KametiDependencies(
        kametis = StubKametiRepository(kametis), ledger = unused, payments = unused, invites = unused, audit = unused,
        profiles = profiles, contacts = unused, auth = auth,
    )
}

private fun kameti(id: String, owner: String) = Kameti(
    id = id, ownerId = owner, name = id, startMonth = DateOnly.make(2026, 10), monthsN = 4,
    slotAmountC = Money(100_000), dueDay = 10, reminderDays = listOf(1), maxSlotsPerMember = 4, status = KametiStatus.Active,
)

/** Twin of ProfileViewModelTests.swift. Each bundle has its own on-phone cache, so tests start with nothing saved. */
class ProfileViewModelTest {
    @Test
    fun loadsTheProfileAndCountsRoles() = runTest {
        val deps = makeDependencies(kametis = listOf(kameti("a", "u1"), kameti("b", "u1"), kameti("c", "u2")))
        val model = ProfileViewModel("u1", deps)
        model.load()
        val state = model.state.value
        assertEquals("Hassan", state.profile?.displayName)
        assertEquals(2, state.runningCount)
        assertEquals(1, state.memberCount)
        assertNull(state.failure)
        assertFalse(state.isLoading)
    }

    @Test
    fun aFailedLoadIsReportedAndCanBeRetried() = runTest {
        val profiles = FakeProfileRepository(Attempt.Failed(Failure.Network))
        val model = ProfileViewModel("u-retry", makeDependencies(auth = FakeAuthRepository("u-retry"), profiles = profiles))
        model.load()
        assertEquals(Failure.Network, model.state.value.failure)
        assertNull(model.state.value.profile)

        profiles.set(Attempt.Success(Profile("u1", "Hassan")))
        model.load()
        assertNull(model.state.value.failure)
        assertNotNull(model.state.value.profile)
    }

    @Test
    fun signOutCallsTheAuthRepository() = runTest {
        val auth = FakeAuthRepository("u1")
        ProfileViewModel("u1", makeDependencies(auth = auth)).signOut()
        assertEquals(listOf("signOut"), auth.calls)
        assertNull(auth.currentUserId)
    }

    @Test
    fun aFailedSignOutIsReported() = runTest {
        val auth = FakeAuthRepository("u1")
        auth.setSignOut(Attempt.Failed(Failure.Network))
        val model = ProfileViewModel("u1", makeDependencies(auth = auth))
        model.signOut()
        assertEquals(Failure.Network, model.state.value.failure)
        assertEquals("u1", auth.currentUserId)
    }

    // Android only: what is saved on the phone shows without a second call to the server.
    @Test
    fun aSecondLoadUsesWhatIsSavedOnThePhone() = runTest {
        val profiles = FakeProfileRepository()
        val deps = makeDependencies(profiles = profiles).copy(contacts = SampleData.dependencies().contacts)
        ProfileViewModel("u1", deps).load()
        ProfileViewModel("u1", deps).load()
        assertEquals(listOf("u1"), profiles.loadedUserIds)
    }
}

/**
 * Twin of ProfileSettingsTests.swift: profile rows against the demo store:
 * name, people, past kametis and sign-in methods.
 */
class ProfileSettingsTest {
    @Test
    fun loadsPeoplePastKametisAndSignInMethods() = runTest {
        val model = ProfileViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val state = model.state.value
        assertEquals(state.people.size, state.peopleCount)
        assertEquals(state.people.map { it.name }.sortedBy { it.lowercase() }, state.people.map { it.name })
        assertEquals(listOf("past-2025"), state.pastKametis.map { it.id })
        assertEquals(1, state.pastCount)
        assertEquals(listOf(SignInMethod(SignInMethod.Provider.Apple, "demo@kameti.test")), state.signInMethods)
    }

    @Test
    fun renaming() = runTest {
        val model = ProfileViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        assertNull(model.updateName("  Hassan Malik "))
        assertEquals("Hassan Malik", model.state.value.profile?.displayName)
        assertEquals(Failure.Server("invalid_name"), model.updateName("   "))
        assertEquals("Hassan Malik", model.state.value.profile?.displayName)
    }

    // Android only: the name prompt after an Apple or Google sign-in, asked once.
    @Test
    fun theNamePromptIsAskedOnce() = runTest {
        val model = ProfileViewModel(SampleData.USER_ID, SampleData.dependencies())
        assertFalse(model.needsNamePrompt) // nothing loaded yet
        model.load()
        assertEquals(true, model.needsNamePrompt)
        model.markNamePrompted()
        assertFalse(model.needsNamePrompt)
    }

    @Test
    fun aNameMadeUpBySignUpIsAPlaceholder() {
        val apple = listOf(SignInMethod(SignInMethod.Provider.Apple, "x7d2k9@privaterelay.appleid.com"))
        fun state(name: String) = ProfileUiState(profile = Profile("u", name), signInMethods = apple)
        assertEquals(true, state("Kameti user").nameIsPlaceholder)
        assertEquals(true, state("x7d2k9").nameIsPlaceholder)
        assertEquals(true, state("  ").nameIsPlaceholder)
        assertFalse(state("Hassan Malik").nameIsPlaceholder)
    }

    @Test
    fun searchingPeople() {
        val people = listOf(
            Contact(id = "1", ownerId = "u", name = "Ali Raza", email = "ali@x.com", phone = null),
            Contact(id = "2", ownerId = "u", name = "Sara Khan", email = null, phone = "0300 1234567"),
        )
        assertEquals(people, matchingPeople(people, "  "))
        assertEquals(listOf("1"), matchingPeople(people, "ALI").map { it.id })
        assertEquals(listOf("1"), matchingPeople(people, "x.com").map { it.id })
        assertEquals(listOf("2"), matchingPeople(people, "1234").map { it.id })
    }
}

/** Twin of DeleteAccountTests: account deletion from Profile (REQUIREMENTS §5.5). */
class DeleteAccountTest {
    /** An account repository that can be told to allow or refuse. */
    private class StubAccount(private val check: AccountDeletionCheck) : AccountRepository {
        override suspend fun deletionCheck(): AccountDeletionCheck = check
        override suspend fun deleteAccount() {
            if (!check.canDelete) throw Failure.Server("owner_has_active_kametis")
        }
    }

    @Test
    fun theDemoOwnerIsBlockedByRunningKametis() = runTest {
        val model = ProfileViewModel(SampleData.USER_ID, SampleData.dependencies())
        val check = assertIs<Attempt.Success<AccountDeletionCheck>>(model.deletionCheck()).value
        assertFalse(check.canDelete)
        assertEquals(setOf("family", "friends"), check.blockingKametis.map { it.id }.toSet())
        assertEquals(listOf("neighbours"), check.draftsToDelete.map { it.id })
        assertEquals(listOf("past-2025"), check.ownedKametisKept.map { it.id })
        assertEquals(Failure.Server("owner_has_active_kametis"), model.deleteAccount())
    }

    @Test
    fun aSuccessfulDeleteSignsOut() = runTest {
        val auth = FakeAuthRepository("u1")
        val deps = SampleData.dependencies().copy(
            auth = auth, account = StubAccount(AccountDeletionCheck(canDelete = true, membershipsToUnlink = 2)),
        )
        assertNull(ProfileViewModel("u1", deps).deleteAccount())
        assertNull(auth.currentUserId)
    }

    @Test
    fun theBackendCheckDecodes() {
        val json = """{"can_delete":false,"blocking_kametis":[{"id":"k1","name":"Office","status":"active"}],"drafts_to_delete":[],"owned_kametis_kept":[],"memberships_to_unlink":3,"contacts_to_delete":12}"""
        val check = KametiJson.json.decodeFromString<AccountDeletionCheck>(json)
        assertFalse(check.canDelete)
        assertEquals(listOf(AccountDeletionCheck.KametiRef("k1", "Office", KametiStatus.Active)), check.blockingKametis)
        assertEquals(3, check.membershipsToUnlink)
        assertEquals(12, check.contactsToDelete)
    }
}
