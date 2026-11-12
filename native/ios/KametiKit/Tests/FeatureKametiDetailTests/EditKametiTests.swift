import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// Editing a running kameti (FR-10, FR-34) against the demo store, which
/// follows the backend's `update_kameti_draft` rules.
@MainActor
@Suite("Edit kameti")
struct EditKametiTests {
    private func loaded() async -> (KametiDetailViewModel, () -> KametiDetailData?) {
        let model = KametiDetailViewModel(kametiId: "family", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        return (model, {
            if case .loaded(let data) = model.state { return data }
            return nil
        })
    }

    @Test func onlyChangedFieldsAreSent() async throws {
        let (_, data) = await loaded()
        let kameti = try #require(data()).kameti
        var form = EditKametiForm(kameti)
        #expect(form.changes(from: kameti) == nil)
        form.name = "  Family kameti 2026 "
        form.toggleReminder(2)
        let changes = try #require(form.changes(from: kameti))
        #expect(changes.name == "Family kameti 2026")
        #expect(changes.reminderDays == [1, 2, 3])
        #expect(changes.dueDay == nil)
        #expect(changes.description == nil)
        #expect(changes.slotAmount == nil && changes.months == nil)
    }

    @Test func anEarlierDueDayDropsLaterReminders() async throws {
        let (_, data) = await loaded()
        var form = EditKametiForm(try #require(data()).kameti)
        form.reminderDays = [1, 3, 8]
        form.setDueDay(5)
        #expect(form.reminderDays == [1, 3])
    }

    @Test func nameAndDescriptionLimits() async throws {
        let (_, data) = await loaded()
        var form = EditKametiForm(try #require(data()).kameti)
        form.name = "ab"
        #expect(form.nameError != nil)
        #expect(!form.isValid)
        form.name = "Family"
        form.description = String(repeating: "x", count: 501)
        #expect(form.descriptionError != nil)
    }

    @Test func savingARunningKameti() async throws {
        let (model, data) = await loaded()
        #expect(await model.updateKameti(KametiChanges(name: "Family kameti 2026", description: "Cousins", dueDay: 12, reminderDays: [1, 5])) == nil)
        let kameti = try #require(data()).kameti
        #expect(kameti.name == "Family kameti 2026")
        #expect(kameti.description == "Cousins")
        #expect(kameti.dueDay == 12)
        #expect(kameti.reminderDays == [1, 5])
        #expect(kameti.status == .active)
    }

    @Test func theMoneyShapeIsFixedOnceStarted() async {
        let (model, _) = await loaded()
        #expect(await model.updateKameti(KametiChanges(slotAmount: Money(300_000))) == .server(code: "kameti_not_draft", detail: nil))
        #expect(await model.updateKameti(KametiChanges(months: 8)) == .server(code: "kameti_not_draft", detail: nil))
        // Another active kameti already has this name.
        #expect(await model.updateKameti(KametiChanges(name: "Friends kameti")) == .server(code: "kameti_name_taken", detail: nil))
    }
}
