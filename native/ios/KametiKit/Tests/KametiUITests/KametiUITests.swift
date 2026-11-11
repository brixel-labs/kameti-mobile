import KametiCore
import Testing
@testable import KametiUI

@Suite("KametiUI logic")
struct KametiUITests {
    @Test func potPercent() {
        #expect(KPotProgress.percent(of: Money(2_350_000), target: Money(5_000_000)) == 47)
        #expect(KPotProgress.percent(of: Money(5_100_000), target: Money(5_000_000)) == 102)
        #expect(KPotProgress.percent(of: Money(100), target: .zero) == 0)
    }

    @Test func barSegmentsAddUpAndClamp() {
        let s = KPotProgress.segments(collected: Money(2_500_000), marked: Money(1_000_000), target: Money(5_000_000))
        #expect(s.collected == 500)
        #expect(s.marked == 200)
        #expect(s.rest == 300)

        let over = KPotProgress.segments(collected: Money(6_000_000), marked: .zero, target: Money(5_000_000))
        #expect(over.collected == 1000)
        #expect(over.rest == 0)
    }

    @Test func balanceMeaning() {
        #expect(KBalancePill.State(balance: Money(450_000)) == .owes(Money(450_000)))
        #expect(KBalancePill.State(balance: .zero) == .settled)
        #expect(KBalancePill.State(balance: Money(-125_000)) == .credit(Money(125_000)))
    }

    @Test func initials() {
        #expect(KAvatar.initials(of: "Ali Raza") == "AR")
        #expect(KAvatar.initials(of: "Hassan") == "H")
        #expect(KAvatar.initials(of: "  muhammad  hassan  khan ") == "MK")
        #expect(KAvatar.initials(of: "") == "")
    }

    @Test func avatarPaletteWrapsAndTokensAreComplete() {
        #expect(KColors.avatars.count == 8)
        _ = KColors.avatar(8)
        _ = KColors.avatar(-1)
        #expect(KSpace.gutter == 20)
        #expect(KSize.minTouch == 44)
    }
}

@Suite("Error help text")
struct ErrorHelpTests {
    @Test func offlineGetsConnectionAdviceOthersTheirMessage() {
        #expect(Failure.network.helpMessage == "Check your connection and try again.")
        #expect(Failure.server(code: "not_kameti_owner", detail: nil).helpMessage == Failure.server(code: "not_kameti_owner", detail: nil).userMessage)
    }
}
