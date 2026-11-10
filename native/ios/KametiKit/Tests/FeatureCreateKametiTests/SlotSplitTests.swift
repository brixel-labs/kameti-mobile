import KametiCore
import Testing
@testable import FeatureCreateKameti

@Suite("SlotSplit")
struct SlotSplitTests {
    private let total = Money(200_000)

    @Test func onePersonGetsTheWholeSlot() {
        var split = SlotSplit(total: total)
        split.add("a")
        #expect(split.amount(of: "a") == total)
        #expect(split.isValid)
        #expect(split.remaining.isZero)
    }

    @Test func anAddedPersonStartsAtZeroAndTheOthersKeepTheirAmounts() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b")
        #expect(split.lines.map(\.amount) == [total, .zero])
        #expect(split.hasUnset)
        #expect(!split.isValid)
    }

    @Test func settingOnePersonSharesTheRestEvenlyBetweenTheOthers() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b")
        split.set("b", to: Money(75_000))
        #expect(split.lines.map(\.amount) == [Money(125_000), Money(75_000)])
        #expect(split.isValid)

        split.add("c")
        split.set("a", to: Money(100_000))
        #expect(split.lines.map(\.amount) == [Money(100_000), Money(50_000), Money(50_000)])
        #expect(split.isValid)

        split.set("a", to: Money(25_000))
        #expect(split.lines.map(\.amount) == [Money(25_000), Money(88_000), Money(87_000)])
        #expect(split.assigned == total)
    }

    @Test func theTotalNeverDrifts() {
        var split = SlotSplit(total: total)
        for id in ["a", "b", "c", "d"] { split.add(id) }
        split.splitEvenly()
        for (id, value) in [("a", 1_234), ("b", 90_000), ("c", 500_000), ("d", 0), ("a", 60_000)] {
            split.set(id, to: Money(value))
            #expect(split.assigned == total)
            #expect(split.isValid)
        }
    }

    @Test func nudgeStepsByTheSlotScaledUnit() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b"); split.splitEvenly()
        split.nudge("a", by: -1)
        #expect(split.lines.map(\.amount) == [Money(75_000), Money(125_000)])
        #expect(SlotSplit.step(for: Money(100_000)) == 5_000)
        #expect(SlotSplit.step(for: Money(20_000)) == 1_000)
    }

    @Test func aPersonCannotTakeSoMuchThatOthersGetLessThanAThousand() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b"); split.add("c")
        split.set("a", to: Money(10_000_000))
        #expect(split.amount(of: "a") == Money(198_000))
        #expect(split.lines.map(\.amount) == [Money(198_000), Money(1_000), Money(1_000)])
        split.set("a", to: Money(0))
        #expect(split.amount(of: "a") == Money(1_000))
        #expect(split.assigned == total)
    }

    @Test func removingKeepsTheOthersUnlessOnlyOneIsLeft() {
        var split = SlotSplit(total: Money(300_000))
        split.add("a"); split.add("b"); split.add("c")
        split.splitEvenly()
        split.remove("c")
        #expect(split.lines.map(\.amount) == [Money(100_000), Money(100_000)])
        #expect(split.remaining == Money(100_000))
        split.remove("b")
        #expect(split.lines.map(\.id) == ["a"])
        #expect(split.amount(of: "a") == Money(300_000))
    }

    @Test func atMostFourPeopleAndNoDuplicates() {
        var split = SlotSplit(total: total)
        for id in ["a", "b", "c", "d", "e"] { split.add(id) }
        split.add("a")
        #expect(split.lines.count == 4)
        #expect(split.isFull)
    }

    @Test func splitEvenlyGivesTheFirstPersonTheRemainder() {
        var split = SlotSplit(total: Money(100_000))
        split.add("a"); split.add("b"); split.add("c")
        split.splitEvenly()
        #expect(split.lines.map(\.amount) == [Money(34_000), Money(33_000), Money(33_000)])
    }

    @Test func presetsOnlyIncludeAmountsThatLeaveRoomForTheOthers() {
        #expect(SlotSplit.presets(for: Money(200_000), people: 2).map(\.rupees) == [25_000, 50_000, 100_000, 150_000])
        #expect(SlotSplit.presets(for: Money(100_000), people: 2).map(\.rupees) == [25_000, 50_000])
        #expect(SlotSplit.presets(for: Money(100_000), people: 4).map(\.rupees) == [25_000, 50_000])
        #expect(SlotSplit.presets(for: Money(2_000), people: 2).isEmpty)
    }
}
