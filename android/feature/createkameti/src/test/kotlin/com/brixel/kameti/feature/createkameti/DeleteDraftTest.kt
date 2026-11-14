package com.brixel.kameti.feature.createkameti

import com.brixel.kameti.core.Failure
import com.brixel.kameti.testsupport.SampleData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

/** Twin of DeleteDraftTests.swift: deleting a draft from the wizard. */
class DeleteDraftTest {
    @Test
    fun aDraftStartedInTheWizardCanBeDeleted() = runTest {
        val dependencies = SampleData.dependencies()
        val model = CreateWizardViewModel(SampleData.USER_ID, dependencies)
        // Nothing on the server yet: nothing to delete.
        assertNull(model.deleteDraft())

        model.setName("Test kameti")
        model.setAmountText("100000")
        model.setMonths(2)
        model.saveBasics()
        val id = assertNotNull(model.state.value.kametiId)
        assertTrue(dependencies.kametis.listKametis().any { it.id == id })

        assertNull(model.deleteDraft())
        assertFalse(dependencies.kametis.listKametis().any { it.id == id })
        assertEquals(Failure.Server("not_found"), assertFailsWith<Failure> { dependencies.kametis.kameti(id) })
    }

    @Test
    fun aRunningKametiCantBeDeletedThisWay() = runTest {
        val dependencies = SampleData.dependencies()
        assertEquals(Failure.Server("kameti_not_draft"), assertFailsWith<Failure> { dependencies.kametis.deleteKametiDraft("family") })
        // Someone else's kameti isn't theirs to delete either.
        assertEquals(Failure.Server("not_kameti_owner"), assertFailsWith<Failure> { dependencies.kametis.deleteKametiDraft("no-such-kameti") })
        assertTrue(dependencies.kametis.listKametis().any { it.id == "family" })
    }
}
