package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.testsupport.SampleData
import java.io.File
import java.time.Instant
import java.time.ZoneOffset
import javax.xml.parsers.DocumentBuilderFactory
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The app's English strings, read from `strings.xml`, so tests can check
 * whole sentences the way the iOS tests do.
 */
internal val english: Strings by lazy {
    val names = R.string::class.java.fields.associate { it.getInt(null) to it.name }
    val nodes = DocumentBuilderFactory.newInstance().newDocumentBuilder()
        .parse(File("src/main/res/values/strings.xml")).getElementsByTagName("string")
    val text = (0 until nodes.length).associate { index ->
        val node = nodes.item(index)
        node.attributes.getNamedItem("name").nodeValue to
            node.textContent.removeSurrounding("\"").replace("\\'", "'").replace("\\\"", "\"").replace("\\n", "\n")
    }
    val lookup: Strings = { id, args -> String.format(text.getValue(names.getValue(id)), *args) }
    lookup
}

private suspend fun loaded(kametiId: String = "family", dependencies: KametiDependencies = SampleData.dependencies()) =
    KametiDetailViewModel(kametiId, SampleData.USER_ID, dependencies).also { it.load() }

private val KametiDetailViewModel.data: KametiDetailData
    get() = assertIs<KametiDetailViewModel.State.Loaded>(state.value).data

private fun obj(vararg pairs: Pair<String, JsonElement>) = JsonObject(mapOf(*pairs))
private fun str(value: String) = JsonPrimitive(value)
private fun int(value: Int) = JsonPrimitive(value)

/**
 * Twin of ActivityTests.swift: the activity log (FR-90): turning audit entries
 * into rows, filters and grouping, and who sees what, against the demo store.
 */
class ActivityTest {
    private val kameti = Kameti(
        id = "k", ownerId = "me", name = "Family", startMonth = DateOnly.make(2026, 10), monthsN = 6,
        slotAmountC = Money(250_000), dueDay = 10, reminderDays = listOf(1, 3), maxSlotsPerMember = 4,
        status = KametiStatus.Active,
    )
    private val context = ActivityLogic.Context(
        members = listOf(Member(id = "m1", kametiId = "k", name = "Ali Raza", joinStatus = JoinStatus.Joined)),
        slots = listOf(Slot("s1", "k", 1)), kameti = kameti, strings = english,
    )
    private var nextId = 0L

    private fun entry(
        action: String,
        member: String? = "m1",
        entityId: String? = null,
        before: JsonElement? = null,
        after: JsonElement? = null,
        hoursAgo: Long = 0,
    ) = AuditEntry(
        id = ++nextId, kametiId = "k", action = action, entity = action.substringBefore("."),
        at = DateOnly.make(2026, 11, 10).atTime(12, 0).toInstant(ZoneOffset.UTC).minusSeconds(hoursAgo * 3600),
        memberId = member, entityId = entityId, before = before, after = after,
    )

    @Test
    fun paymentsReadAsSentences() {
        val paid = ActivityLogic.item(entry("payment.record", after = obj("amount" to int(125_000), "method" to str("cash"))), context)
        assertEquals("Payment recorded", paid.title)
        assertEquals("Rs 1,25,000 from Ali Raza · cash", paid.detail)
        assertEquals(ActivityItem.Category.Money, paid.category)
        val voided = ActivityLogic.item(
            entry("payment.void", after = obj("amount" to int(50_000), "void_reason" to str("Recorded twice"))), context,
        )
        assertEquals("Rs 50,000 from Ali Raza · “Recorded twice”", voided.detail)
        val payout = ActivityLogic.item(entry("payout.record", after = obj("amount" to int(1_500_000), "slot_id" to str("s1"))), context)
        assertEquals("October payout paid out", payout.title)
        assertEquals("Rs 15,00,000 to Ali Raza", payout.detail)
    }

    @Test
    fun editsListOnlyWhatChanged() {
        val edit = ActivityLogic.item(
            entry(
                "kameti.update", member = null,
                before = obj("name" to str("Family"), "due_day" to int(10), "reminder_days" to JsonArray(listOf(int(1), int(3), int(8)))),
                after = obj("name" to str("Family"), "due_day" to int(12), "reminder_days" to JsonArray(listOf(int(1), int(3)))),
            ),
            context,
        )
        assertEquals(
            listOf(
                ActivityItem.Change("Due day", "10th", "12th"),
                ActivityItem.Change("Reminders", "1st, 3rd, 8th", "1st, 3rd"),
            ),
            edit.changes,
        )
    }

    @Test
    fun aChangedReminderTimeReadsAsATime() {
        val edit = ActivityLogic.item(
            entry("kameti.update", member = null, before = obj("reminder_hour" to int(10)), after = obj("reminder_hour" to int(18))),
            context,
        )
        assertEquals(listOf(ActivityItem.Change("Reminder time", "10:00 AM", "6:00 PM")), edit.changes)
    }

    @Test
    fun aRemovedMemberIsNamedFromTheEntry() {
        val removed = ActivityLogic.item(entry("member.remove", member = "gone", before = obj("name" to str("Old Friend"))), context)
        assertEquals("Old Friend removed", removed.title)
    }

    @Test
    fun aListOfSharesDecodesAndReads() {
        // slot.set_shares stores lists, not objects: the whole log must still load.
        val json = """{"id":7,"kameti_id":"k","action":"slot.set_shares","entity":"slot","entity_id":"s1","at":"2026-11-10T09:00:00Z","before":[],"after":[{"member_id":"m1","monthly_amount":250000}]}"""
        val decoded = KametiJson.json.decodeFromString<AuditEntry>(json)
        assertEquals(1, (decoded.after as? JsonArray)?.size)
        assertEquals("Shares changed on the October payout", ActivityLogic.item(decoded, context).title)
    }

    @Test
    fun filtersAndDays() {
        val items = ActivityLogic.items(
            listOf(
                entry("payment.record", after = obj("amount" to int(1_000)), hoursAgo = 1),
                entry("member.add", hoursAgo = 2),
                entry("kameti.start", member = null, hoursAgo = 30),
            ),
            context,
        )
        assertEquals(1, ActivityLogic.filtered(items, ActivityLogic.Filter.Money).size)
        assertEquals(1, ActivityLogic.filtered(items, ActivityLogic.Filter.Members).size)
        assertEquals(1, ActivityLogic.filtered(items, ActivityLogic.Filter.Changes).size)
        val days = ActivityLogic.byDay(items)
        assertEquals(2, days.size)
        assertEquals(2, days[0].second.size) // newest day first
    }

    @Test
    fun theOwnerSeesTheHistoryAndNewActions() = runTest {
        val dependencies = SampleData.dependencies()
        val model = ActivityViewModel("family", SampleData.USER_ID, dependencies)
        model.load()
        assertIs<ActivityViewModel.State.Loaded>(model.state.value)
        assertTrue(model.items(english).any { it.title == "Kameti edited" })
        val before = model.items(english).size
        dependencies.payments.recordPayment(NewPayment("f4", Money(10_000), DateOnly.make(2026, 11, 10), "k1"))
        model.load()
        assertEquals(before + 1, model.items(english).size)
        assertEquals("Payment recorded", model.items(english).first().title)
    }

    @Test
    fun aMemberSeesOnlyEntriesAboutThem() = runTest {
        val model = ActivityViewModel("office", SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val items = model.items(english)
        assertTrue(items.isNotEmpty())
        assertTrue(items.all { it.detail?.contains("Demo Owner") == true })
    }
}

/**
 * Twin of EditKametiTests.swift: editing a running kameti (FR-10, FR-34)
 * against the demo store, which follows the backend's `update_kameti_draft` rules.
 */
class EditKametiTest {
    @Test
    fun onlyChangedFieldsAreSent() = runTest {
        val kameti = loaded().data.kameti
        var form = EditKametiForm(kameti)
        assertNull(form.changes(kameti))
        form = form.copy(name = "  Family kameti 2026 ").toggleReminder(2)
        val changes = assertNotNull(form.changes(kameti))
        assertEquals("Family kameti 2026", changes.name)
        assertEquals(listOf(1, 2, 3), changes.reminderDays)
        assertNull(changes.dueDay)
        assertNull(changes.description)
        assertTrue(changes.slotAmount == null && changes.months == null)
    }

    @Test
    fun theReminderTimeIsEditableAndSent() = runTest {
        val model = loaded()
        val kameti = model.data.kameti
        assertEquals(10, kameti.reminderHour)
        val form = EditKametiForm(kameti).copy(reminderHour = 18)
        val changes = assertNotNull(form.changes(kameti))
        assertEquals(18, changes.reminderHour)
        assertTrue(changes.name == null && changes.dueDay == null && changes.reminderDays == null)
        assertNull(model.updateKameti(changes))
        assertEquals(18, model.data.kameti.reminderHour)
        assertEquals(Failure.Server("invalid_reminder_hour"), model.updateKameti(KametiChanges(reminderHour = 3)))
    }

    @Test
    fun anEarlierDueDayDropsLaterReminders() = runTest {
        val form = EditKametiForm(loaded().data.kameti).copy(reminderDays = listOf(1, 3, 8)).setDueDay(5)
        assertEquals(listOf(1, 3), form.reminderDays)
    }

    @Test
    fun nameAndDescriptionLimits() = runTest {
        var form = EditKametiForm(loaded().data.kameti).copy(name = "ab")
        assertFalse(form.isNameValid)
        assertFalse(form.isValid)
        form = form.copy(name = "Family", description = "x".repeat(501))
        assertFalse(form.isDescriptionValid)
    }

    @Test
    fun savingARunningKameti() = runTest {
        val model = loaded()
        assertNull(model.updateKameti(KametiChanges(name = "Family kameti 2026", description = "Cousins", dueDay = 12, reminderDays = listOf(1, 5))))
        val kameti = model.data.kameti
        assertEquals("Family kameti 2026", kameti.name)
        assertEquals("Cousins", kameti.description)
        assertEquals(12, kameti.dueDay)
        assertEquals(listOf(1, 5), kameti.reminderDays)
        assertEquals(KametiStatus.Active, kameti.status)
    }

    @Test
    fun theMoneyShapeIsFixedOnceStarted() = runTest {
        val model = loaded()
        assertEquals(Failure.Server("kameti_not_draft"), model.updateKameti(KametiChanges(slotAmount = Money(300_000))))
        assertEquals(Failure.Server("kameti_not_draft"), model.updateKameti(KametiChanges(months = 8)))
        // Another active kameti already has this name.
        assertEquals(Failure.Server("kameti_name_taken"), model.updateKameti(KametiChanges(name = "Friends kameti")))
    }
}

/**
 * Twin of NotesTests.swift: notes against the demo store, which follows the
 * backend's rules: the owner sees and writes everything; a member sees only
 * shared notes about them or the whole kameti (FR-70 to FR-72).
 */
class NotesTest {
    @Test
    fun theOwnerSeesEveryNoteNewestFirst() = runTest {
        val current = loaded().data
        assertEquals(listOf("n1", "n2", "n3", "n4"), current.notes.map { it.id })
        assertEquals(2, NoteLogic.count(current.notes, NoteLogic.Filter.Private))
        assertEquals(2, NoteLogic.count(current.notes, NoteLogic.Filter.Shared))
        assertEquals("Ali Raza", NoteLogic.targetLabel(current.notes[0], current, english))
        assertEquals("October payout", NoteLogic.targetLabel(current.notes[2], current, english))
        assertEquals("Kameti", NoteLogic.targetLabel(current.notes[3], current, english))
    }

    @Test
    fun aMemberSeesOnlySharedNotesAboutThemOrTheKameti() = runTest {
        // Not the private one, and not the shared one about Zainab.
        assertEquals(setOf("o-n1", "o-n2"), loaded("office").data.notes.map { it.id }.toSet())
    }

    @Test
    fun filterAndSearch() = runTest {
        val current = loaded().data
        fun ids(filter: NoteLogic.Filter, search: String) =
            NoteLogic.visible(current.notes, filter, search, current, english).map { it.id }
        assertEquals(listOf("n2", "n4"), ids(NoteLogic.Filter.Shared, ""))
        assertEquals(listOf("n4"), ids(NoteLogic.Filter.All, "meezan"))
        // The search also matches what a note is about.
        assertEquals(listOf("n3"), ids(NoteLogic.Filter.All, "october payout"))
    }

    @Test
    fun addEditShareAndDelete() = runTest {
        val model = loaded()
        assertNull(model.addNote(NewNote("  Faisal will pay by cheque  ", targetType = NoteTarget.Member, targetId = "f6")))
        val added = model.data.notes.first()
        assertEquals("Faisal will pay by cheque", added.body)
        assertEquals(NoteVisibility.Private, added.visibility)
        assertEquals("f6", added.targetId)

        assertNull(model.updateNote(added.id, body = null, visibility = NoteVisibility.Shared))
        val shared = model.data.notes.first { it.id == added.id }
        assertEquals(NoteVisibility.Shared, shared.visibility)
        assertTrue(shared.isEdited)

        assertNull(model.deleteNote(added.id))
        assertFalse(model.data.notes.any { it.id == added.id })
    }

    @Test
    fun badNotesAreRefused() = runTest {
        val model = loaded()
        assertEquals(Failure.Server("invalid_note_body"), model.addNote(NewNote("   ")))
        assertEquals(
            Failure.Server("target_not_found"),
            model.addNote(NewNote("x", targetType = NoteTarget.Member, targetId = "nobody")),
        )
        assertEquals(Failure.Server("nothing_to_change"), model.updateNote("n1", body = null, visibility = null))
    }

    @Test
    fun aMemberCantWriteNotes() = runTest {
        assertEquals(Failure.Server("not_kameti_owner"), loaded("office").addNote(NewNote("hello")))
    }

    @Test
    fun dayText() {
        val today = DateOnly.make(2026, 11, 10)
        fun at(day: java.time.LocalDate, hours: Long): Instant = day.atStartOfDay().toInstant(ZoneOffset.UTC).plusSeconds(hours * 3600)
        assertEquals("Today", NoteLogic.dayText(at(today, 8), today, english))
        assertEquals("Yesterday", NoteLogic.dayText(at(today, -10), today, english))
        val third = DateOnly.make(2026, 11, 3)
        assertEquals(DetailLogic.dayMonth(third), NoteLogic.dayText(at(third, 8), today, english))
    }
}

/**
 * Twin of ArchiveKametiTests.swift: archive and restore (§6.11) against the
 * demo store, which follows the backend's `archive_kameti` / `restore_kameti` rules.
 */
class ArchiveKametiTest {
    @Test
    fun archiveThenRestoreReturnsToActive() = runTest {
        val model = loaded()
        assertEquals(KametiStatus.Active, model.data.kameti.status)
        assertNull(model.archive())
        assertEquals(KametiStatus.Archived, model.data.kameti.status)
        assertNull(model.restore())
        assertEquals(KametiStatus.Active, model.data.kameti.status)
    }

    @Test
    fun archivingTwiceFails() = runTest {
        val model = loaded()
        assertNull(model.archive())
        assertEquals(Failure.Server("kameti_already_archived"), model.archive())
    }

    @Test
    fun restoringNeedsAnArchivedKameti() = runTest {
        assertEquals(Failure.Server("kameti_not_archived"), loaded().restore())
    }

    @Test
    fun archivedKametisStillListForPast() = runTest {
        val dependencies = SampleData.dependencies()
        loaded(dependencies = dependencies).archive()
        assertEquals(KametiStatus.Archived, dependencies.kametis.listKametis().first { it.id == "family" }.status)
    }

    @Test
    fun archivingUnblocksAccountDeletion() = runTest {
        val dependencies = SampleData.dependencies()
        val before = dependencies.account.deletionCheck()
        assertFalse(before.canDelete)
        for (ref in before.blockingKametis) dependencies.kametis.archiveKameti(ref.id)
        assertTrue(dependencies.account.deletionCheck().canDelete)
    }

    @Test
    fun nameTakenMessageExplainsTheFix() {
        val hint = assertNotNull(changeFailureHint(Failure.Server("kameti_name_taken")))
        assertTrue("Rename" in english.get(hint))
        assertNull(changeFailureHint(Failure.Network))
    }
}

/** Twin of DuplicateKametiTests: duplicating a kameti as a new draft (FR-13) against the demo store. */
class DuplicateKametiTest {
    private val suffix: (Int) -> String = { attempt ->
        if (attempt <= 1) english.get(R.string.detail_copy_b9f2) else english.get(R.string.detail_copy_n, attempt)
    }

    @Test
    fun copiesMembersAndSharesButNoPayments() = runTest {
        val dependencies = SampleData.dependencies()
        val model = loaded(dependencies = dependencies)
        val source = model.data

        val id = assertIs<Attempt.Success<String>>(model.duplicate(suffix)).value
        val copy = dependencies.kametis.kameti(id)
        assertEquals(KametiStatus.Draft, copy.status)
        assertEquals("Family kameti (copy)", copy.name)
        assertTrue(copy.monthsN == source.kameti.monthsN && copy.slotAmountC == source.kameti.slotAmountC)
        assertEquals(DuplicateLogic.startMonth(source.kameti, dependencies.clock.currentMonth()), copy.startMonth)

        val members = dependencies.kametis.members(id)
        assertEquals(source.members.map { it.name }, members.map { it.name })
        assertTrue(members.all { it.profileId == null || it.profileId == SampleData.USER_ID })
        assertEquals(source.shares.count { it.effectiveToMonth == null }, dependencies.kametis.shares(id).size)
        assertTrue(dependencies.payments.payments(id).isEmpty())

        // A second copy gets the next free name.
        val second = assertIs<Attempt.Success<String>>(model.duplicate(suffix)).value
        assertEquals("Family kameti (copy 2)", dependencies.kametis.kameti(second).name)
    }

    @Test
    fun namesStayWithinTheLimit() {
        val long = "a".repeat(40)
        assertTrue(DuplicateLogic.name(long, suffix(1)).length <= 40)
        assertTrue(DuplicateLogic.name(long, suffix(3)).endsWith("(copy 3)"))
    }
}

/** Twin of TransferShareTests: transferring a share (FR-33) against the demo store. */
class TransferShareTest {
    @Test
    fun movesTheShareFromThisMonth() = runTest {
        val model = loaded()
        val before = model.data
        val ali = before.members.first { it.id == "f1" }
        val share = TransferLogic.movableShares(ali, before).first()
        val from = assertNotNull(TransferLogic.firstMonth(share, before))
        val to = TransferLogic.candidates(share, before).first()

        assertNull(model.transferShare(share.id, KametiDetailViewModel.TransferTarget.Existing(to.id), from, "Cash settled"))
        val after = model.data
        val ended = after.shares.first { it.id == share.id }
        val moved = after.shares.first { it.slotId == share.slotId && it.memberId == to.id && it.effectiveToMonth == null }
        assertEquals(share.monthlyAmount, moved.monthlyAmount)
        if (from > share.effectiveFromMonth) {
            assertEquals(from - 1, ended.effectiveToMonth)
            assertEquals(from, moved.effectiveFromMonth)
        }
    }

    @Test
    fun aNewPersonIsAddedFirst() = runTest {
        val model = loaded()
        val before = model.data
        val share = TransferLogic.movableShares(before.members.first { it.id == "f1" }, before).first()
        val from = assertNotNull(TransferLogic.firstMonth(share, before))
        assertNull(model.transferShare(share.id, KametiDetailViewModel.TransferTarget.NewPerson("Zoya Ahmed"), from, null))
        val after = model.data
        val zoya = after.members.first { it.name == "Zoya Ahmed" }
        assertTrue(after.shares.any { it.memberId == zoya.id && it.slotId == share.slotId })
    }

    @Test
    fun pastMonthsAreRefused() = runTest {
        val model = loaded()
        val before = model.data
        val share = TransferLogic.movableShares(before.members.first { it.id == "f1" }, before).first()
        val to = TransferLogic.candidates(share, before).first()
        assertEquals(
            Failure.Server("invalid_transfer_month"),
            model.transferShare(share.id, KametiDetailViewModel.TransferTarget.Existing(to.id), 99, null),
        )
    }
}
