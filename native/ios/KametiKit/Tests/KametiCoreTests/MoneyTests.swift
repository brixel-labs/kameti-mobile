import Foundation
import Testing
@testable import KametiCore

@Suite("Money")
struct MoneyTests {
    @Test("format uses lakh/crore grouping", arguments: [
        (0, "Rs 0"), (999, "Rs 999"), (1000, "Rs 1,000"), (50000, "Rs 50,000"),
        (125_000, "Rs 1,25,000"), (2_500_000, "Rs 25,00,000"), (4_970_000, "Rs 49,70,000"),
        (5_000_000, "Rs 50,00,000"), (12_345_678, "Rs 1,23,45,678"),
    ])
    func format(rupees: Int, expected: String) {
        #expect(Money(rupees).format() == expected)
    }

    @Test func negativeAmountsUseAMinusSign() {
        #expect(Money(-125_000).format() == "−Rs 1,25,000")
    }

    @Test func formatWithoutSymbol() {
        #expect(Money(250_000).format(symbol: false) == "2,50,000")
    }

    @Test("compact format", arguments: [
        (500, "500"), (50_000, "50K"), (100_000, "1 L"), (125_000, "1.25 L"),
        (2_500_000, "25 L"), (24_000_000, "2.4 Cr"),
    ])
    func compact(rupees: Int, expected: String) {
        #expect(Money(rupees).formatCompact() == expected)
    }

    @Test func parsesGroupedAndPlainInput() {
        #expect(Money(parsing: "2,50,000") == Money(250_000))
        #expect(Money(parsing: " 250000 ") == Money(250_000))
    }

    @Test func rejectsEmptyDecimalsAndText() {
        #expect(Money(parsing: "") == nil)
        #expect(Money(parsing: "12.5") == nil)
        #expect(Money(parsing: "abc") == nil)
    }

    @Test func slotMathShareTimesMonthsIsThePayout() {
        // REQUIREMENTS section 3: payout per sharer = share x N.
        #expect(Money(125_000) * 20 == Money(2_500_000))
    }

    @Test func rupeeThousandSteps() {
        #expect(Money(63_000).isMultiple(of: Money(1000)))
        #expect(!Money(62_500).isMultiple(of: Money(1000)))
        #expect(!Money(1000).isMultiple(of: .zero))
    }

    @Test func comparisonAndSums() {
        let a = Money(50_000), b = Money(100_000)
        #expect(a + b == Money(150_000))
        #expect(b - a == a)
        #expect(a < b)
        #expect((a - b).isNegative)
        #expect((-a).abs() == a)
    }

    @Test func decodesFromABareInteger() throws {
        let money = try JSONDecoder().decode(Money.self, from: Data("250000".utf8))
        #expect(money == Money(250_000))
        #expect(try JSONEncoder().encode(money) == Data("250000".utf8))
    }
}
