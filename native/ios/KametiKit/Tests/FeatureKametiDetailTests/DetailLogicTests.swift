import Foundation
import KametiCore
import KametiDomain
import Testing
@testable import FeatureKametiDetail

private let kameti = Kameti(
    id: "k", ownerId: "o", name: "K", startMonth: DateOnly.make(year: 2026, month: 11), monthsN: 4,
    slotAmountC: Money(100_000), dueDay: 10, reminderDays: [], maxSlotsPerMember: 4, status: .active
)
private func member(_ id: String, profile: String? = nil) -> Member {
    Member(id: id, kametiId: "k", name: id, joinStatus: .joined, profileId: profile)
}
private func share(_ id: String, slot: String, member: String, amount: Int, from: Int = 1, to: Int? = nil) -> Share {
    Share(id: id, kametiId: "k", slotId: slot, memberId: member, monthlyAmount: Money(amount), effectiveFromMonth: from, effectiveToMonth: to)
}
private func row(_ month: Int, _ status: MonthStatusCode, member: String = "a") -> MemberMonthRow {
    MemberMonthRow(
        kametiId: "k", memberId: member, monthIndex: month, monthStart: DateOnly.make(year: 2026, month: 10 + month),
        isCurrent: false, due: Money(1000), allocated: .zero, remaining: Money(1000), status: status
    )
}

@Suite("DetailLogic")
struct DetailLogicTests {
    @Test func monthStartCrossesTheYear() {
        #expect(DetailLogic.monthStart(of: kameti, monthIndex: 1) == DateOnly.make(year: 2026, month: 11))
        #expect(DetailLogic.monthStart(of: kameti, monthIndex: 3) == DateOnly.make(year: 2027, month: 1))
    }

    @Test func shareActivityHonoursItsWindow() {
        let s = share("s", slot: "x", member: "a", amount: 1, from: 2, to: 3)
        #expect(!DetailLogic.isActive(s, in: 1))
        #expect(DetailLogic.isActive(s, in: 2))
        #expect(DetailLogic.isActive(s, in: 3))
        #expect(!DetailLogic.isActive(s, in: 4))
        #expect(DetailLogic.isActive(share("o", slot: "x", member: "a", amount: 1), in: 99))
    }

    @Test func recipientsGetShareTimesNAndSplitSlotsShowEveryone() {
        let slots = [Slot(id: "s1", kametiId: "k", payoutMonthIndex: 1), Slot(id: "s2", kametiId: "k", payoutMonthIndex: 2)]
        let shares = [
            share("a1", slot: "s1", member: "a", amount: 60_000),
            share("b1", slot: "s1", member: "b", amount: 40_000),
            share("a2", slot: "s2", member: "a", amount: 100_000),
        ]
        let result = DetailLogic.recipients(kameti: kameti, monthIndex: 1, slots: slots, shares: shares, members: [member("a"), member("b")])
        #expect(result.map(\.member.id) == ["a", "b"])
        #expect(result.map(\.payout) == [Money(240_000), Money(160_000)])
        #expect(DetailLogic.recipients(kameti: kameti, monthIndex: 3, slots: slots, shares: shares, members: [member("a")]).isEmpty)
    }

    @Test func myMemberMatchesByProfile() {
        let list = [member("a", profile: "u1"), member("b", profile: "u2")]
        #expect(DetailLogic.myMember(in: list, userId: "u2")?.id == "b")
        #expect(DetailLogic.myMember(in: list, userId: "zzz") == nil)
        #expect(DetailLogic.myMember(in: list, userId: nil) == nil)
    }

    @Test func owingKeepsPartialUnpaidOverdueOfThatMonth() {
        let rows = [row(1, .paid), row(1, .partial), row(1, .unpaid), row(1, .overdue), row(1, .advance), row(2, .unpaid)]
        #expect(DetailLogic.owing(rows, monthIndex: 1).map(\.status) == [.partial, .unpaid, .overdue])
    }

    @Test func statusCountsGroupAdvanceWithPaidAndOverdueWithUnpaid() {
        let rows = [row(1, .paid), row(1, .advance), row(1, .partial), row(1, .overdue), row(1, .unpaid), row(1, .upcoming), row(2, .paid)]
        #expect(DetailLogic.statusCounts(rows, monthIndex: 1) == .init(paid: 2, partial: 1, unpaid: 2))
    }

    @Test func nextTurnIsTheEarliestUpcomingShare() {
        let slots = [Slot(id: "s1", kametiId: "k", payoutMonthIndex: 1), Slot(id: "s3", kametiId: "k", payoutMonthIndex: 3)]
        let shares = [share("1", slot: "s1", member: "a", amount: 100_000), share("3", slot: "s3", member: "a", amount: 50_000)]
        let me = member("a")
        #expect(DetailLogic.nextTurn(for: me, kameti: kameti, from: 1, slots: slots, shares: shares)?.monthIndex == 1)
        let next = DetailLogic.nextTurn(for: me, kameti: kameti, from: 2, slots: slots, shares: shares)
        #expect(next?.monthIndex == 3)
        #expect(next?.payout == Money(200_000))
        #expect(DetailLogic.nextTurn(for: me, kameti: kameti, from: 4, slots: slots, shares: shares) == nil)
    }

    @Test func paymentsAreNewestFirst() {
        func pay(_ id: String, day: Int, created: Int) -> Payment {
            Payment(id: id, kametiId: "k", memberId: "a", amount: Money(1), receivedOn: DateOnly.make(year: 2026, month: 11, day: day),
                    method: .cash, createdAt: Date(timeIntervalSince1970: TimeInterval(created)))
        }
        let sorted = DetailLogic.newestFirst([pay("old", day: 1, created: 1), pay("newA", day: 5, created: 1), pay("newB", day: 5, created: 9)])
        #expect(sorted.map(\.id) == ["newB", "newA", "old"])
    }

    @Test func paymentSubtitleSkipsEmptyParts() {
        let full = Payment(id: "p", kametiId: "k", memberId: "a", amount: Money(1), receivedOn: Date(), method: .bankTransfer,
                           createdAt: Date(), reference: "88213", paidByName: "Hassan")
        #expect(DetailLogic.paymentSubtitle(full, methodLabel: "Bank", paidBy: { "paid by \($0)" }) == "Bank · 88213 · paid by Hassan")
        let bare = Payment(id: "p", kametiId: "k", memberId: "a", amount: Money(1), receivedOn: Date(), method: .cash, createdAt: Date(), reference: "")
        #expect(DetailLogic.paymentSubtitle(bare, methodLabel: "Cash", paidBy: { $0 }) == "Cash")
    }
}
