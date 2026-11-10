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

    @Test func secondPersonSplitsEvenlyThenAmountsCanChange() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b")
        #expect(split.lines.map(\.amount) == [Money(100_000), Money(100_000)])
        split.set("a", to: Money(150_000))
        #expect(split.amount(of: "a") == Money(150_000))
        #expect(split.remaining == Money(-50_000))
        #expect(!split.isValid)
        split.set("b", to: Money(50_000))
        #expect(split.isValid)
    }

    @Test func nudgeStepsByTheSlotScaledUnit() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b")
        split.nudge("a", by: -1)
        #expect(split.amount(of: "a") == Money(75_000))
        #expect(split.remaining == Money(25_000))
        #expect(SlotSplit.step(for: Money(100_000)) == 5_000)
        #expect(SlotSplit.step(for: Money(20_000)) == 1_000)
    }

    @Test func amountsLeaveRoomForTheOthers() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b"); split.add("c")
        split.set("a", to: Money(10_000_000))
        #expect(split.amount(of: "a") == Money(198_000)) // 2 others keep at least 1,000 each
        split.set("a", to: Money(0))
        #expect(split.amount(of: "a") == Money(1_000))
        split.set("a", to: Money(12_345))
        #expect(split.amount(of: "a") == Money(12_000))
    }

    @Test func removingDownToOneGivesTheWholeSlotAgain() {
        var split = SlotSplit(total: total)
        split.add("a"); split.add("b")
        split.remove("b")
        #expect(split.lines.map(\.id) == ["a"])
        #expect(split.amount(of: "a") == total)
    }

    @Test func removingFromThreeKeepsTheOthersAsTheyAre() {
        var split = SlotSplit(total: Money(300_000))
        split.add("a"); split.add("b"); split.add("c")
        split.remove("c")
        #expect(split.lines.map(\.amount) == [Money(100_000), Money(100_000)])
        #expect(split.remaining == Money(100_000))
    }

    @Test func atMostFourPeopleAndNoDuplicates() {
        var split = SlotSplit(total: total)
        for id in ["a", "b", "c", "d", "e"] { split.add(id) }
        split.add("a")
        #expect(split.lines.count == 4)
        #expect(split.isFull)
        #expect(split.isValid)
    }

    @Test func resetSplitsEvenlyAndTheFirstTakesTheRemainder() {
        var split = SlotSplit(total: Money(100_000))
        split.add("a"); split.add("b"); split.add("c")
        #expect(split.lines.map(\.amount) == [Money(34_000), Money(33_000), Money(33_000)])
        split.set("a", to: Money(10_000))
        split.splitEvenly()
        #expect(split.lines.map(\.amount) == [Money(34_000), Money(33_000), Money(33_000)])
    }

    @Test func presetsOnlyIncludeAmountsThatLeaveRoom() {
        #expect(SlotSplit.presets(for: Money(200_000)).map(\.rupees) == [25_000, 50_000, 100_000, 150_000, 200_000].filter { $0 + 1_000 <= 200_000 })
        #expect(SlotSplit.presets(for: Money(100_000)).map(\.rupees) == [25_000, 50_000])
        #expect(SlotSplit.presets(for: Money(2_000)).isEmpty)
    }
}
