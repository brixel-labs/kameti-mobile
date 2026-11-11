import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// The activity log (FR-90): turning audit entries into rows, filters and
/// grouping, and who sees what, against the demo store.
@MainActor
@Suite("Activity")
struct ActivityTests {
    private let kameti = Kameti(
        id: "k", ownerId: "me", name: "Family", startMonth: DateOnly.make(year: 2026, month: 10), monthsN: 6,
        slotAmountC: Money(250_000), dueDay: 10, reminderDays: [1, 3], maxSlotsPerMember: 4, status: .active
    )
    private var context: ActivityLogic.Context {
        ActivityLogic.Context(
            members: [Member(id: "m1", kametiId: "k", name: "Ali Raza", joinStatus: .joined)],
            slots: [Slot(id: "s1", kametiId: "k", payoutMonthIndex: 1)], kameti: kameti
        )
    }
    private func entry(_ action: String, member: String? = "m1", entityId: String? = nil, before: JSONValue? = nil, after: JSONValue? = nil, hoursAgo: Double = 0) -> AuditEntry {
        AuditEntry(id: Int.random(in: 1...1_000_000), kametiId: "k", action: action, entity: action.components(separatedBy: ".")[0],
                   at: DateOnly.make(year: 2026, month: 11, day: 10).addingTimeInterval(12 * 3600 - hoursAgo * 3600),
                   memberId: member, entityId: entityId, before: before, after: after)
    }

    @Test func paymentsReadAsSentences() {
        let paid = ActivityLogic.item(entry("payment.record", after: .object(["amount": .int(125_000), "method": .string("cash")])), context)
        #expect(paid.title == "Payment recorded")
        #expect(paid.detail == "Rs 1,25,000 from Ali Raza · cash")
        #expect(paid.category == .money)
        let voided = ActivityLogic.item(entry("payment.void", after: .object(["amount": .int(50_000), "void_reason": .string("Recorded twice")])), context)
        #expect(voided.detail == "Rs 50,000 from Ali Raza · “Recorded twice”")
        let payout = ActivityLogic.item(entry("payout.record", after: .object(["amount": .int(1_500_000), "slot_id": .string("s1")])), context)
        #expect(payout.title == "October payout paid out")
        #expect(payout.detail == "Rs 15,00,000 to Ali Raza")
    }

    @Test func editsListOnlyWhatChanged() {
        let edit = ActivityLogic.item(entry("kameti.update", member: nil,
            before: .object(["name": .string("Family"), "due_day": .int(10), "reminder_days": .array([.int(1), .int(3), .int(8)])]),
            after: .object(["name": .string("Family"), "due_day": .int(12), "reminder_days": .array([.int(1), .int(3)])])), context)
        #expect(edit.changes == [
            .init(label: "Due day", before: "10th", after: "12th"),
            .init(label: "Reminders", before: "1st, 3rd, 8th", after: "1st, 3rd"),
        ])
    }

    @Test func aRemovedMemberIsNamedFromTheEntry() {
        let removed = ActivityLogic.item(entry("member.remove", member: "gone", before: .object(["name": .string("Old Friend")])), context)
        #expect(removed.title == "Old Friend removed")
    }

    @Test func aListOfSharesDecodesAndReads() throws {
        // slot.set_shares stores lists, not objects: the whole log must still load.
        let json = #"{"id":7,"kameti_id":"k","action":"slot.set_shares","entity":"slot","entity_id":"s1","at":"2026-11-10T09:00:00Z","before":[],"after":[{"member_id":"m1","monthly_amount":250000}]}"#
        let decoded = try KametiJSON.makeDecoder().decode(AuditEntry.self, from: Data(json.utf8))
        #expect(decoded.after?.arrayValue?.count == 1)
        #expect(ActivityLogic.item(decoded, context).title == "Shares changed on the October payout")
    }

    @Test func filtersAndDays() {
        let items = ActivityLogic.items([
            entry("payment.record", after: .object(["amount": .int(1_000)]), hoursAgo: 1),
            entry("member.add", hoursAgo: 2),
            entry("kameti.start", member: nil, hoursAgo: 30),
        ], context)
        #expect(ActivityLogic.filtered(items, .money).count == 1)
        #expect(ActivityLogic.filtered(items, .members).count == 1)
        #expect(ActivityLogic.filtered(items, .changes).count == 1)
        let days = ActivityLogic.byDay(items)
        #expect(days.count == 2)
        #expect(days[0].items.count == 2) // newest day first
    }

    @Test func theOwnerSeesTheHistoryAndNewActions() async throws {
        let dependencies = SampleData.dependencies()
        let model = ActivityViewModel(kametiId: "family", userId: SampleData.userId, dependencies: dependencies)
        await model.load()
        #expect(model.state == .loaded)
        #expect(model.items.contains { $0.title == "Kameti edited" })
        let before = model.items.count
        _ = try await dependencies.payments.recordPayment(NewPayment(
            memberId: "f4", amount: Money(10_000), receivedOn: DateOnly.make(year: 2026, month: 11, day: 10), idempotencyKey: "k1"
        ))
        await model.load()
        #expect(model.items.count == before + 1)
        #expect(model.items.first?.title == "Payment recorded")
    }

    @Test func aMemberSeesOnlyEntriesAboutThem() async {
        let model = ActivityViewModel(kametiId: "office", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        #expect(!model.items.isEmpty)
        #expect(model.items.allSatisfy { $0.detail?.contains("Demo Owner") == true })
    }
}
