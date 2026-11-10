import KametiCore
import Testing
@testable import FeatureCreateKameti

@Suite("SlotSplit")
struct SlotSplitTests {
    private let total = Money(200_000)

    @Test func everyoneStartsAtZeroAndNothingIsAdjustedOnAdd() {
        var split = SlotSplit(total: total)
        split.add("a")
        #expect(split.lines.map(\.amount) == [.zero])
        #expect(split.hasUnset && !split.isValid && !split.canAdd)
        split.set("a", to: Money(100_000))
        split.add("b")
        #expect(split.lines.map(\.amount) == [Money(100_000), .zero])
    }

    @Test func choosingTheWholeSlotCompletesItAndHidesAdding() {
        var split = SlotSplit(total: total)
        split.add("a")
        split.set("a", to: total)
        #expect(split.isValid)
        #expect(!split.canAdd)
        #expect(split.remaining.isZero)
    }

    @Test func aPartialAmountLeavesRoomToAddSomeoneWithOnlyWhatFits() {
        var split = SlotSplit(total: total)
        split.add("a"); split.set("a", to: Money(100_000))
        #expect(split.canAdd)
        split.add("b")
        #expect(split.options(for: "b").map(\.rupees) == [25_000, 50_000, 100_000])
        #expect(split.options(for: "a").map(\.rupees) == [25_000, 50_000, 100_000, 150_000, 200_000])
    }

    @Test func nothingCanGoOver() {
        var split = SlotSplit(total: total)
        split.add("a"); split.set("a", to: Money(150_000))
        split.add("b")
        split.set("b", to: Money(200_000))
        #expect(split.amount(of: "b") == Money(50_000))
        #expect(split.assigned == total)
        split.nudge("b", by: 1)
        #expect(split.assigned == total)
        split.set("a", to: Money(9_000_000))
        #expect(split.amount(of: "a") == Money(150_000))
    }

    @Test func optionsScaleWithTheSlotAmount() {
        var big = SlotSplit(total: Money(500_000))
        big.add("a")
        #expect(big.options(for: "a").map(\.rupees) == [25_000, 50_000, 100_000, 150_000, 200_000, 250_000, 300_000, 400_000, 500_000])
        big.set("a", to: Money(300_000)); big.add("b")
        #expect(big.options(for: "b").map(\.rupees) == [25_000, 50_000, 100_000, 150_000, 200_000])
        var small = SlotSplit(total: Money(75_000))
        small.add("a")
        #expect(small.options(for: "a").map(\.rupees) == [25_000, 50_000, 75_000])
    }

    @Test func atMostThreePeople() {
        var split = SlotSplit(total: Money(300_000))
        split.add("a"); split.set("a", to: Money(100_000))
        split.add("b"); split.set("b", to: Money(100_000))
        split.add("c"); split.set("c", to: Money(50_000))
        split.add("d")
        #expect(split.lines.count == 3)
        #expect(split.isFull && !split.canAdd)
        #expect(!split.isValid)
        #expect(split.remaining == Money(50_000))
        split.add("a")
        #expect(split.lines.count == 3)
    }

    @Test func removingChangesNobodyAndAddingIsPossibleAgain() {
        var split = SlotSplit(total: total)
        split.add("a"); split.set("a", to: Money(100_000))
        split.add("b"); split.set("b", to: Money(100_000))
        #expect(split.isValid && !split.canAdd)
        split.remove("b")
        #expect(split.lines.map(\.amount) == [Money(100_000)])
        #expect(split.remaining == Money(100_000))
        #expect(split.canAdd)
    }

    @Test func amountsStayInThousandsAndAtLeastOneThousand() {
        var split = SlotSplit(total: total)
        split.add("a")
        split.set("a", to: Money(12_345)); #expect(split.amount(of: "a") == Money(12_000))
        split.set("a", to: Money(0)); #expect(split.amount(of: "a") == Money(1_000))
    }

    @Test func nudgeStepsByTheSlotScaledUnit() {
        var split = SlotSplit(total: total)
        split.add("a"); split.set("a", to: Money(100_000))
        split.nudge("a", by: -1)
        #expect(split.amount(of: "a") == Money(75_000))
        #expect(SlotSplit.step(for: Money(100_000)) == 5_000)
        #expect(SlotSplit.step(for: Money(20_000)) == 1_000)
    }

    @Test func splitEvenlyGivesTheFirstPersonTheRemainder() {
        var split = SlotSplit(total: Money(100_000))
        split.add("a"); split.set("a", to: Money(1_000)); split.add("b"); split.set("b", to: Money(1_000)); split.add("c")
        split.splitEvenly()
        #expect(split.lines.map(\.amount) == [Money(34_000), Money(33_000), Money(33_000)])
        #expect(split.isValid)
    }
}
