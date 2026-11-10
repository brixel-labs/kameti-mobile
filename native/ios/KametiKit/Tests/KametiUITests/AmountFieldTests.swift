import Testing
@testable import KametiUI

@Suite("KAmountField")
struct AmountFieldTests {
    @Test func groupsInLakhAndCrore() {
        #expect(KAmountField.grouped("250000") == "2,50,000")
        #expect(KAmountField.grouped("1000") == "1,000")
        #expect(KAmountField.grouped("12345678") == "1,23,45,678")
        #expect(KAmountField.grouped("") == "")
        #expect(KAmountField.grouped("abc") == "")
    }
}
