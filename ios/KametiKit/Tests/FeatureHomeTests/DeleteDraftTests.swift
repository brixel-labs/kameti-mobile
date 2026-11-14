import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureHome

/// Deleting one of my drafts from Home.
@MainActor
@Suite("Delete a draft from Home")
struct HomeDeleteDraftTests {
    @Test func theDraftLeavesHome() async {
        let model = HomeViewModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        #expect(model.sections.mine.contains { $0.id == "neighbours" }) // the demo draft
        #expect(await model.deleteDraft(id: "neighbours") == nil)
        #expect(!model.sections.mine.contains { $0.id == "neighbours" })
    }

    @Test func aRunningKametiStaysAndTheFailureIsReturned() async {
        let model = HomeViewModel(userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        #expect(await model.deleteDraft(id: "family") == .server(code: "kameti_not_draft", detail: nil))
        #expect(model.sections.mine.contains { $0.id == "family" })
    }
}
