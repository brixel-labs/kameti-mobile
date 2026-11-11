import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureCreateKameti

/// Reopening a saved draft in the create wizard.
@MainActor
@Suite("Resume draft")
struct ResumeDraftTests {
    private let slots = (1...3).map { Slot(id: "s\($0)", kametiId: "k", payoutMonthIndex: $0) }

    private func share(_ slot: Int) -> Share {
        Share(id: "h\(slot)", kametiId: "k", slotId: "s\(slot)", memberId: "m1", monthlyAmount: Money(100_000), effectiveFromMonth: 1)
    }

    @Test func continuesAtTheFirstUnfinishedStep() {
        let member = Member(id: "m1", kametiId: "k", name: "Ali", joinStatus: .notInvited)
        #expect(CreateWizardModel.resumeStep(members: [], slots: slots, shares: []) == .members)
        #expect(CreateWizardModel.resumeStep(members: [member], slots: slots, shares: [share(1)]) == .slots)
        #expect(CreateWizardModel.resumeStep(members: [member], slots: slots, shares: [share(1), share(2), share(3)]) == .review)
    }

    @Test func reopeningTheDemoDraftFillsEveryStep() async {
        let model = CreateWizardModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.resume(draftId: "neighbours")
        #expect(model.failure == nil)
        #expect(model.isResumed)
        #expect(model.kametiId == "neighbours")
        #expect(model.name == "Neighbours kameti")
        #expect(model.amountText == "150000")
        #expect(model.months == 3)
        #expect(model.dueDay == 5)
        #expect(model.reminderDays == [1, 3])
        #expect(model.maxSlotsPerMember == 2)
        #expect(model.members.count == 2)
        #expect(model.emails["nb1"] == "ali.raza@gmail.com")
        // Slot 1 is filled; 2 and 3 aren't, so it continues on Slots.
        #expect(model.step == .slots)
    }

    @Test func aMissingDraftShowsTheFailure() async {
        let model = CreateWizardModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.resume(draftId: "nope")
        #expect(model.failure != nil)
        #expect(!model.isResumed)
        #expect(model.step == .basics)
    }
}
