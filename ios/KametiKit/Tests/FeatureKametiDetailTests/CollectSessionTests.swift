import KametiCore
import Testing
@testable import FeatureKametiDetail

private func session() -> CollectSession {
    CollectSession(lines: [
        .init(memberId: "a", remaining: Money(450_000)),
        .init(memberId: "b", remaining: Money(125_000)),
        .init(memberId: "c", remaining: Money(50_000)),
    ])
}

@Suite("CollectSession")
struct CollectSessionTests {
    @Test func tapMarksWhatTheyOweAndTapAgainUndoes() {
        var s = session()
        s.toggle("a")
        #expect(s.state(of: "a") == .settled(Money(450_000)))
        #expect(s.total == Money(450_000) && s.count == 1)
        s.toggle("a")
        #expect(s.state(of: "a") == .unmarked)
        #expect(s.total.isZero && s.count == 0)
    }

    @Test func editingLessLeavesThemOwingTheRest() {
        var s = session()
        s.set("a", to: Money(200_000))
        #expect(s.state(of: "a") == .partial(Money(200_000), stillOwes: Money(250_000)))
        s.set("a", to: Money(450_000)); #expect(s.state(of: "a") == .settled(Money(450_000)))
        s.set("a", to: Money(500_000)); #expect(s.state(of: "a") == .settled(Money(500_000)))
        s.set("a", to: .zero); #expect(s.state(of: "a") == .unmarked)
    }

    @Test func markAllThenClearAll() {
        var s = session()
        s.toggle("b")
        s.markAll()
        #expect(s.allMarked && s.count == 3)
        #expect(s.total == Money(625_000))
        s.markAll()
        #expect(s.count == 0)
    }

    @Test func itemsFollowTheListAndUseOneKeyPerMember() {
        var s = session()
        s.set("c", to: Money(50_000)); s.toggle("a")
        let items = s.items(keys: ["a": "ka", "c": "kc"])
        #expect(items.map(\.memberId) == ["a", "c"])
        #expect(items.map(\.idempotencyKey) == ["ka", "kc"])
        #expect(items.map(\.amount) == [Money(450_000), Money(50_000)])
    }

    @Test func peopleNotInTheListCannotBeMarked() {
        var s = session()
        s.toggle("zzz"); s.set("zzz", to: Money(1_000))
        #expect(s.count == 0)
    }
}
