import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// Members who don't use the app: marking them, who the Overview is still waiting for, and the receipt
/// and update texts sent to them by WhatsApp.
@MainActor
@Suite("Guest members")
struct GuestTests {
    private func loaded(_ id: String = "family") async -> (KametiDetailViewModel, () -> KametiDetailData?) {
        let model = KametiDetailViewModel(kametiId: id, userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        return (model, {
            if case .loaded(let data) = model.state { return data }
            return nil
        })
    }

    @Test func setupProgressCountsWhoIsStillToJoin() async throws {
        let (model, data) = await loaded()
        let start = SetupProgress.of(try #require(data()))
        #expect(start.expected == 6)
        #expect(start.waiting.map(\.id) == ["f5", "f6"])
        #expect(start.needsApproval) // Hira is waiting for the owner's approval
        #expect(!start.isComplete)

        #expect(await model.approveJoin(memberId: "f5") == nil)
        let approved = SetupProgress.of(try #require(data()))
        #expect(approved.waiting.map(\.id) == ["f6"])
        #expect(!approved.needsApproval)
    }

    @Test func aGuestIsNotWaitedFor() async throws {
        let (model, data) = await loaded()
        #expect(await model.addMember(NewMember(name: "Zara Ahmed")) == nil)
        let afterAdd = try #require(data())
        let zara = try #require(afterAdd.members.first { $0.name == "Zara Ahmed" })
        #expect(SetupProgress.of(try #require(data())).waiting.contains { $0.id == zara.id })
        #expect(SetupProgress.of(try #require(data())).expected == 7)

        #expect(await model.setNoApp(memberId: zara.id, true) == nil)
        let marked = try #require(data())
        let markedZara = try #require(marked.members.first { $0.id == zara.id })
        #expect(AccessState.of(markedZara, in: marked) == .guest(phone: nil))
        let progress = SetupProgress.of(marked)
        #expect(progress.expected == 6)
        #expect(progress.waiting.map(\.id) == ["f5", "f6"])
        // Invite all leaves them out.
        #expect(!AccessState.invitable(in: marked).contains { $0.id == zara.id })

        #expect(await model.setNoApp(memberId: zara.id, false) == nil)
        #expect(SetupProgress.of(try #require(data())).expected == 7)
    }

    @Test func aMemberWithAnInviteCantBeAGuest() async {
        let (model, _) = await loaded()
        #expect(await model.setNoApp(memberId: "f6", true) == .server(code: "member_already_invited", detail: nil)) // invited
        #expect(await model.setNoApp(memberId: "f1", true) == .server(code: "member_already_invited", detail: nil)) // joined
    }

    @Test func theOwnersOwnRowDoesNotCount() async throws {
        let (_, data) = await loaded("office")
        let progress = SetupProgress.of(try #require(data()))
        #expect(progress.expected == 3)
        #expect(progress.isComplete)
    }

    @Test func aReceiptIsOfferedOnlyToGuests() async throws {
        let (model, data) = await loaded()
        #expect(await model.addMember(NewMember(name: "Zara Ahmed")) == nil)
        let afterAdd = try #require(data())
        let zara = try #require(afterAdd.members.first { $0.name == "Zara Ahmed" })
        #expect(await model.setNoApp(memberId: zara.id, true) == nil)
        let day = DateOnly.make(year: 2026, month: 11, day: 10)
        await model.offerReceipts([
            PendingReceipt(memberId: "f1", amount: Money(10_000), on: day),
            PendingReceipt(memberId: zara.id, amount: Money(5_000), on: day),
        ])
        #expect(model.pendingReceipts.map(\.memberId) == [zara.id])
        model.pendingReceipts = []
        await model.offerReceipts([PendingReceipt(memberId: "f1", amount: Money(10_000), on: day)])
        #expect(model.pendingReceipts.isEmpty)
    }

    @Test func theTextSaysOnlyWhatTheMemberOwesAndGets() async throws {
        let (_, data) = await loaded()
        let current = try #require(data())
        let osama = try #require(current.members.first { $0.id == "f4" })
        let update = GuestUpdate.text(for: osama, in: current)
        #expect(update.hasPrefix("Hi Osama, here's your Family kameti update for November."))
        #expect(update.contains("You owe Rs"))
        #expect(!update.contains("Naveed")) // nobody else's name or figures

        let day = DateOnly.make(year: 2026, month: 11, day: 10)
        let receipt = GuestUpdate.text(for: osama, in: current, receipt: PendingReceipt(memberId: "f4", amount: Money(10_000), on: day))
        #expect(receipt.hasPrefix("Hi Osama, we received Rs 10,000 from you on \(DetailLogic.dayMonth(day)) for Family kameti."))
        #expect(update.contains("Your payout is in")) // Osama's turn

        // Whatever the balance says: owing, ahead or paid up.
        func standing(_ owes: Int, _ credit: Int) -> String {
            let balance = MemberBalanceRow(
                kametiId: "family", memberId: "f2", currentMonthIndex: 2, monthlyDue: Money(250_000), dueToDate: Money(500_000),
                totalPaid: Money(500_000), balance: Money(owes - credit), owes: Money(owes), credit: Money(credit)
            )
            let changed = KametiDetailData(
                kameti: current.kameti, userId: current.userId, members: current.members, slots: current.slots, shares: current.shares,
                collections: current.collections, balances: [balance], months: current.months, payments: current.payments,
                payouts: current.payouts, today: current.today
            )
            return GuestUpdate.text(for: current.members.first { $0.id == "f2" }!, in: changed)
        }
        #expect(standing(0, 0).contains("You're all paid up."))
        #expect(standing(0, 125_000).contains("You're ahead by Rs 1,25,000."))
        #expect(standing(250_000, 0).contains("You owe Rs 2,50,000 so far, due by the 10th."))
    }
}
