package com.brixel.kameti.feature.createkameti

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.testsupport.SampleData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

private fun makeModel() = CreateWizardViewModel(SampleData.USER_ID, SampleData.dependencies())

/** A draft of two months at Rs 1,00,000 a slot, saved to the (sample) server. */
private suspend fun draft(): CreateWizardViewModel = makeModel().apply {
    setName("Test kameti")
    setAmountText("100000")
    setMonths(2)
    saveBasics()
}

private val CreateWizardViewModel.now get() = state.value

class CreateWizardViewModelTest {
    @Test
    fun basicsValidation() {
        val model = makeModel()
        assertFalse(model.now.nameValid)
        model.setName("Family")
        model.setAmountText("250,000")
        assertTrue(model.now.nameValid)
        assertTrue(model.now.slotAmountValid)
        assertEquals(Money(250_000), model.now.slotAmount)
        model.setAmountText("1500")
        assertFalse(model.now.slotAmountValid)
        model.setAmountText("")
        assertFalse(model.now.slotAmountValid)
        model.setName("ab")
        assertFalse(model.now.nameValid)
    }

    @Test
    fun monthsAndSlotLimitsClamp() {
        val model = makeModel()
        model.setMonths(1); assertEquals(2, model.now.months)
        model.setMonths(99); assertEquals(60, model.now.months)
        model.setMaxSlots(0); assertEquals(1, model.now.maxSlotsPerMember)
        model.setMaxSlots(9); assertEquals(6, model.now.maxSlotsPerMember)
    }

    @Test
    fun changingTheDueDayDropsLaterReminders() {
        val model = makeModel()
        model.setDueDay(6)
        assertEquals(listOf(1, 5), model.now.reminderDays)
        model.toggleReminder(3)
        assertEquals(listOf(1, 3, 5), model.now.reminderDays)
        model.toggleReminder(1)
        assertEquals(listOf(3, 5), model.now.reminderDays)
    }

    @Test
    fun backClosesTheSplitEditorBeforeLeavingTheStep() {
        val model = makeModel()
        model.goTo(WizardStep.Slots)
        model.editSlot("s1")
        model.back()
        assertEquals(WizardStep.Slots, model.now.step)
        assertNull(model.now.editingSlotId)
        model.back()
        assertEquals(WizardStep.Members, model.now.step)
    }

    @Test
    fun theReminderTimeIsSavedWithTheDates() = runTest {
        val dependencies = SampleData.dependencies()
        val model = CreateWizardViewModel(SampleData.USER_ID, dependencies).apply {
            setName("Test kameti")
            setAmountText("100000")
            setMonths(2)
            saveBasics()
        }
        assertEquals(10, model.now.reminderHour)
        model.setReminderHour(18)
        model.saveDates()
        assertNull(model.now.failure)
        val id = assertNotNull(model.now.kametiId)
        assertEquals(18, dependencies.kametis.kameti(id).reminderHour)

        // Reopened later, the draft shows it again.
        val reopened = CreateWizardViewModel(SampleData.USER_ID, dependencies)
        reopened.resume(id)
        assertEquals(18, reopened.now.reminderHour)
    }

    @Test
    fun fullFlowCreatesFillsAndStarts() = runTest {
        val model = draft()
        assertNull(model.now.failure)
        assertEquals(WizardStep.Dates, model.now.step)
        assertEquals(2, model.now.slots.size)

        model.saveDates()
        assertEquals(WizardStep.Members, model.now.step)

        model.addMember("Ali", "ali@example.com")
        model.setSelfMember(included = true)
        assertEquals(2, model.now.members.size)
        assertNotNull(model.now.selfMember)
        assertEquals(1, model.now.emails.size)
        assertTrue(model.now.pendingMemberIds.isEmpty())

        // Starting with empty slots is refused by the server.
        assertFalse(model.now.checks.passes)
        assertNull(model.start())
        assertNotNull(model.now.failure)

        val ali = model.now.members.first { it.name == "Ali" }
        val me = assertNotNull(model.now.selfMember)
        model.saveSlotShares(model.now.slots[0].id, listOf(ShareInput(ali.id, Money(100_000))))
        model.saveSlotShares(
            model.now.slots[1].id, listOf(ShareInput(me.id, Money(60_000)), ShareInput(ali.id, Money(40_000))),
        )
        assertNull(model.now.failure)
        assertTrue(model.now.checks.passes)

        // Swap the payout order.
        model.saveOrder(model.now.slots.reversed().map { it.id })
        assertEquals(WizardStep.Review, model.now.step)

        assertEquals(model.now.kametiId, model.start())
        assertNull(model.now.failure)
    }

    @Test
    fun aSplitThatDoesNotAddUpIsRefused() = runTest {
        val model = draft()
        model.addMember("Ali", null)
        val ali = model.now.members.first()
        model.saveSlotShares(model.now.slots[0].id, listOf(ShareInput(ali.id, Money(50_000))))
        assertNotNull(model.now.failure)
        assertTrue(model.now.shares.isEmpty())
    }

    @Test
    fun removingAMemberRemovesTheirShares() = runTest {
        val model = draft()
        model.addMember("Ali", null)
        val ali = model.now.members.first()
        model.saveSlotShares(model.now.slots[0].id, listOf(ShareInput(ali.id, Money(100_000))))
        model.removeMember(ali.id)
        assertTrue(model.now.members.isEmpty())
        assertTrue(model.now.shares.isEmpty())
    }

    @Test
    fun aSavedRowKeepsTheKeyItWasFirstShownWith() = runTest {
        val model = draft()
        model.addMember("Ali", null)
        val ali = model.now.members.first()
        assertTrue(model.now.rowKey(ali).startsWith("pending-"))
        assertFalse(model.now.isPending(ali))
    }

    @Test
    fun addingASlotGrowsTheDraftByOneMonth() = runTest {
        val model = draft()
        model.addSlot()
        assertEquals(3, model.now.months)
        assertEquals(3, model.now.slots.size)
        assertEquals(Money(300_000), model.now.pot)
    }

    @Test
    fun savedPeopleCanBePickedAndLeaveTheList() = runTest {
        val model = draft()
        model.loadContacts()
        assertEquals(SampleData.contacts.size, model.now.contacts.size)
        val first = model.now.availableContacts.first()
        model.addMember(first)
        assertNull(model.now.failure)
        assertEquals(listOf(first.name), model.now.members.map { it.name })
        assertFalse(first in model.now.availableContacts)
        assertEquals(SampleData.contacts.size - 1, model.now.availableContacts.size)
    }

    @Test
    fun selectAllAddsEverySavedPersonAtOnce() = runTest {
        val model = draft()
        model.loadContacts()
        model.addMembers(model.now.availableContacts)
        assertNull(model.now.failure)
        assertEquals(SampleData.contacts.size, model.now.members.size)
        assertTrue(model.now.availableContacts.isEmpty())
    }
}

/** Reopening a saved draft in the create wizard. */
class ResumeDraftTest {
    private val slots = (1..3).map { Slot("s$it", "k", it) }
    private fun share(slot: Int) = Share("h$slot", "k", "s$slot", "m1", Money(100_000), effectiveFromMonth = 1)

    @Test
    fun continuesAtTheFirstUnfinishedStep() {
        val member = Member("m1", "k", "Ali", JoinStatus.NotInvited)
        assertEquals(WizardStep.Members, CreateWizardViewModel.resumeStep(emptyList(), slots, emptyList()))
        assertEquals(WizardStep.Slots, CreateWizardViewModel.resumeStep(listOf(member), slots, listOf(share(1))))
        assertEquals(
            WizardStep.Review, CreateWizardViewModel.resumeStep(listOf(member), slots, listOf(share(1), share(2), share(3))),
        )
    }

    @Test
    fun reopeningTheDemoDraftFillsEveryStep() = runTest {
        val model = makeModel()
        model.resume("neighbours")
        val state = model.now
        assertNull(state.failure)
        assertTrue(state.isResumed)
        assertFalse(state.isLoadingDraft)
        assertEquals("neighbours", state.kametiId)
        assertEquals("Neighbours kameti", state.name)
        assertEquals("150000", state.amountText)
        assertEquals(3, state.months)
        assertEquals(5, state.dueDay)
        assertEquals(listOf(1, 3), state.reminderDays)
        assertEquals(2, state.maxSlotsPerMember)
        assertEquals(2, state.members.size)
        assertEquals("ali.raza@gmail.com", state.emails["nb1"])
        // Slot 1 is filled; 2 and 3 aren't, so it continues on Slots.
        assertEquals(WizardStep.Slots, state.step)
    }

    @Test
    fun aMissingDraftShowsTheFailure() = runTest {
        val model = makeModel()
        model.resume("nope")
        assertNotNull(model.now.failure)
        assertFalse(model.now.isResumed)
        assertEquals(WizardStep.Basics, model.now.step)
    }
}
