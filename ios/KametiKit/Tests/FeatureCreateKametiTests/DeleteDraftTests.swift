import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureCreateKameti

/// Deleting a draft from the wizard: it goes for good, and a kameti that is running can't be deleted this way.
@MainActor
@Suite("Delete draft")
struct DeleteDraftTests {
    @Test func aDraftStartedInTheWizardCanBeDeleted() async throws {
        let dependencies = SampleData.dependencies()
        let model = CreateWizardModel(userId: SampleData.userId, dependencies: dependencies)
        // Nothing on the server yet: nothing to delete.
        #expect(await model.deleteDraft() == nil)

        model.name = "Test kameti"
        model.amountText = "100000"
        model.setMonths(2)
        await model.saveBasics()
        let id = try #require(model.kametiId)
        #expect(try await dependencies.kametis.listKametis().contains { $0.id == id })

        #expect(await model.deleteDraft() == nil)
        #expect(try await dependencies.kametis.listKametis().contains { $0.id == id } == false)
        await #expect(throws: Failure.server(code: "not_found", detail: nil)) { _ = try await dependencies.kametis.kameti(id: id) }
    }

    @Test func aRunningKametiCantBeDeletedThisWay() async throws {
        let dependencies = SampleData.dependencies()
        await #expect(throws: Failure.server(code: "kameti_not_draft", detail: nil)) {
            try await dependencies.kametis.deleteKametiDraft(id: "family")
        }
        // Someone else's kameti isn't theirs to delete either.
        await #expect(throws: Failure.server(code: "not_kameti_owner", detail: nil)) {
            try await dependencies.kametis.deleteKametiDraft(id: "no-such-kameti")
        }
        #expect(try await dependencies.kametis.listKametis().contains { $0.id == "family" })
    }
}
