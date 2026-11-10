import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureCreateKameti

@MainActor
private func makeModel() -> CreateWizardModel {
    CreateWizardModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
}

@MainActor
@Suite("CreateWizardModel")
struct CreateWizardModelTests {
    @Test func basicsValidation() {
        let model = makeModel()
        #expect(!model.nameValid)
        model.name = "Family"
        model.amountText = "250,000"
        #expect(model.nameValid)
        #expect(model.slotAmountValid)
        #expect(model.slotAmount == Money(250_000))
        model.amountText = "1500"
        #expect(!model.slotAmountValid)
        model.amountText = ""
        #expect(!model.slotAmountValid)
        model.name = "ab"
        #expect(!model.nameValid)
    }

    @Test func monthsAndSlotLimitsClamp() {
        let model = makeModel()
        model.setMonths(1); #expect(model.months == 2)
        model.setMonths(99); #expect(model.months == 60)
        model.setMaxSlots(0); #expect(model.maxSlotsPerMember == 1)
        model.setMaxSlots(9); #expect(model.maxSlotsPerMember == 6)
    }

    @Test func changingTheDueDayDropsLaterReminders() {
        let model = makeModel()
        model.setDueDay(6)
        #expect(model.reminderDays == [1, 5])
        model.toggleReminder(3)
        #expect(model.reminderDays == [1, 3, 5])
        model.toggleReminder(1)
        #expect(model.reminderDays == [3, 5])
    }

    @Test func backClosesTheSplitEditorBeforeLeavingTheStep() {
        let model = makeModel()
        model.goTo(.slots)
        model.editingSlotId = "s1"
        model.back()
        #expect(model.step == .slots)
        #expect(model.editingSlotId == nil)
        model.back()
        #expect(model.step == .members)
    }

    @Test func fullFlowCreatesFillsAndStarts() async throws {
        let model = makeModel()
        model.name = "Test kameti"
        model.amountText = "100000"
        model.setMonths(2)
        await model.saveBasics()
        #expect(model.failure == nil)
        #expect(model.step == .dates)
        #expect(model.slots.count == 2)

        await model.saveDates()
        #expect(model.step == .members)

        await model.addMember(name: "Ali", email: "ali@example.com")
        await model.setSelfMember(included: true)
        #expect(model.members.count == 2)
        #expect(model.selfMember != nil)
        #expect(model.emails.count == 1)

        // Starting with empty slots is refused by the server.
        #expect(!model.checks.passes)
        #expect(await model.start() == nil)
        #expect(model.failure != nil)

        let ali = try #require(model.members.first { $0.name == "Ali" })
        let me = try #require(model.selfMember)
        await model.saveSlotShares(slotId: model.slots[0].id, shares: [ShareInput(memberId: ali.id, monthlyAmount: Money(100_000))])
        await model.saveSlotShares(slotId: model.slots[1].id, shares: [
            ShareInput(memberId: me.id, monthlyAmount: Money(60_000)), ShareInput(memberId: ali.id, monthlyAmount: Money(40_000)),
        ])
        #expect(model.failure == nil)
        #expect(model.checks.passes)

        // Swap the payout order.
        await model.saveOrder(model.slots.reversed().map(\.id))
        #expect(model.step == .review)

        let id = await model.start()
        #expect(id == model.kametiId)
        #expect(model.failure == nil)
    }

    @Test func aSplitThatDoesNotAddUpIsRefused() async throws {
        let model = makeModel()
        model.name = "Test kameti"
        model.amountText = "100000"
        model.setMonths(2)
        await model.saveBasics()
        await model.addMember(name: "Ali", email: nil)
        let ali = try #require(model.members.first)
        await model.saveSlotShares(slotId: model.slots[0].id, shares: [ShareInput(memberId: ali.id, monthlyAmount: Money(50_000))])
        #expect(model.failure != nil)
        #expect(model.shares.isEmpty)
    }

    @Test func removingAMemberRemovesTheirShares() async throws {
        let model = makeModel()
        model.name = "Test kameti"
        model.amountText = "100000"
        model.setMonths(2)
        await model.saveBasics()
        await model.addMember(name: "Ali", email: nil)
        let ali = try #require(model.members.first)
        await model.saveSlotShares(slotId: model.slots[0].id, shares: [ShareInput(memberId: ali.id, monthlyAmount: Money(100_000))])
        await model.removeMember(ali.id)
        #expect(model.members.isEmpty)
        #expect(model.shares.isEmpty)
    }
}

@MainActor
@Suite("CreateWizardModel contacts")
struct CreateWizardContactsTests {
    @Test func savedPeopleCanBePickedAndLeaveTheList() async throws {
        let model = makeModel()
        model.name = "Test kameti"
        model.amountText = "100000"
        model.setMonths(2)
        await model.saveBasics()
        await model.loadContacts()
        #expect(model.contacts.count == SampleData.contacts.count)
        let first = try #require(model.availableContacts.first)
        await model.addMember(from: first)
        #expect(model.failure == nil)
        #expect(model.members.map(\.name) == [first.name])
        #expect(!model.availableContacts.contains(first))
        #expect(model.availableContacts.count == SampleData.contacts.count - 1)
    }
}
