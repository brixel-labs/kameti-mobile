import Foundation
import KametiCore
import KametiDomain
import Testing
@testable import FeatureKametiDetail

private func row(due: Int, allocated: Int) -> MemberMonthRow {
    MemberMonthRow(
        kametiId: "k", memberId: "m", monthIndex: 2, monthStart: DateOnly.make(year: 2026, month: 11), isCurrent: true,
        due: Money(due), allocated: Money(allocated), remaining: Money(due - allocated), status: .partial
    )
}

@Suite("PaymentLogic")
struct PaymentLogicTests {
    @Test func outcomeForTheAmountEntered() {
        let partial = row(due: 1_000_000, allocated: 550_000) // 4,50,000 left
        #expect(PaymentLogic.outcome(amount: Money(450_000), row: partial) == .fullyPaid)
        #expect(PaymentLogic.outcome(amount: Money(200_000), row: partial) == .stillOwes(Money(250_000)))
        #expect(PaymentLogic.outcome(amount: Money(500_000), row: partial) == .credit(Money(50_000)))
        #expect(PaymentLogic.outcome(amount: .zero, row: partial) == .none)
        #expect(PaymentLogic.outcome(amount: Money(1_000), row: nil) == .none)
    }

    @Test func aMemberAlreadyPaidUpGetsCreditForAnyPayment() {
        #expect(PaymentLogic.outcome(amount: Money(10_000), row: row(due: 100_000, allocated: 100_000)) == .credit(Money(10_000)))
    }
}
