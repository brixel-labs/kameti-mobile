package com.brixel.kameti.feature.home

import com.brixel.kameti.core.Failure
import com.brixel.kameti.testsupport.SampleData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

/** Twin of HomeDeleteDraftTests: deleting one of my drafts from Home. */
class HomeDeleteDraftTest {
    @Test
    fun theDraftLeavesHome() = runTest {
        val model = HomeViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        assertTrue(model.state.value.sections.mine.any { it.id == "neighbours" }) // the demo draft
        assertNull(model.deleteDraft("neighbours"))
        assertFalse(model.state.value.sections.mine.any { it.id == "neighbours" })
    }

    @Test
    fun aRunningKametiStaysAndTheFailureIsReturned() = runTest {
        val model = HomeViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        assertEquals(Failure.Server("kameti_not_draft"), model.deleteDraft("family"))
        assertTrue(model.state.value.sections.mine.any { it.id == "family" })
    }
}
