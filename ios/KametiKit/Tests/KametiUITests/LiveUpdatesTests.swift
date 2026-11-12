import Foundation
import Testing
@testable import KametiUI

/// Live changes fold into one reload, and say which kametis moved.
@MainActor
@Suite("Live updates")
struct LiveUpdatesTests {
    @Test func aBurstBecomesOneReload() async throws {
        let live = KLiveUpdates()
        live.record(kametiId: "a")
        live.record(kametiId: "b")
        #expect(live.revision == 0)
        try await Task.sleep(for: .milliseconds(600))
        #expect(live.revision == 1)
        #expect(live.affects("a") && live.affects("b"))
        #expect(!live.affects("c"))
    }

    @Test func anUnknownKametiRefreshesEverything() async throws {
        let live = KLiveUpdates()
        live.record(kametiId: "a")
        live.record(kametiId: nil)
        try await Task.sleep(for: .milliseconds(600))
        #expect(live.affects("anything"))
    }

    @Test func comingBackRefreshesAtOnce() {
        let live = KLiveUpdates()
        live.refreshAll()
        #expect(live.revision == 1)
        #expect(live.affects("x"))
    }
}
