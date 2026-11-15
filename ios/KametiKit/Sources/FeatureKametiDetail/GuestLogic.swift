import Foundation
import KametiCore
import KametiDomain

/// How far the owner is with getting people onto the app: who is still to join, so the Overview can
/// say so. Members the owner marked as not using the app, and the owner's own row, don't count.
struct SetupProgress: Equatable {
    /// Everyone expected on the app: all members except the owner's own row and the guests.
    let expected: Int
    /// Not joined yet: not invited, invited, or waiting for the owner's approval.
    let waiting: [Member]

    var isComplete: Bool { waiting.isEmpty }
    /// Someone is waiting for the owner to approve them.
    var needsApproval: Bool { waiting.contains { $0.joinStatus == .pendingApproval } }

    static func of(_ data: KametiDetailData) -> SetupProgress {
        var expected = 0
        var waiting: [Member] = []
        for member in data.members {
            switch AccessState.of(member, in: data) {
            case .owner, .guest: break
            case .joined: expected += 1
            case .needsApproval, .invited, .notInvited:
                expected += 1
                waiting.append(member)
            }
        }
        return SetupProgress(expected: expected, waiting: waiting)
    }
}

/// A payment the owner just recorded for a member who isn't on the app, to offer a receipt for.
struct PendingReceipt: Identifiable, Equatable, Sendable {
    let memberId: String
    let amount: Money
    let on: Date
    var id: String { "\(memberId)-\(amount.rupees)-\(on.timeIntervalSince1970)" }
}

/// The short text for a member who isn't on the app (their own figures only, nobody else's): a
/// receipt right after a payment, or the owner's "Send update". Sent by WhatsApp or the share sheet.
enum GuestUpdate {
    static func text(for member: Member, in data: KametiDetailData, receipt: PendingReceipt? = nil, viewLink: String? = nil) -> String {
        let first = MemberLogic.firstName(member.name)
        let kameti = data.kameti.name
        var lines: [String] = []
        if let receipt {
            lines.append(String(localized: "Hi \(first), we received \(receipt.amount.format()) from you on \(DetailLogic.dayMonth(receipt.on)) for \(kameti).", bundle: .module))
        } else {
            let month = data.current.map { String(DetailLogic.monthTitle($0.monthStart).split(separator: " ").first ?? "") } ?? ""
            lines.append(String(localized: "Hi \(first), here's your \(kameti) update for \(month).", bundle: .module))
        }
        if let row = PaymentLogic.monthRow(for: member.id, in: data), row.due.isPositive {
            lines.append(String(localized: "This month: paid \(row.allocated.format()) of \(row.due.format()).", bundle: .module))
        }
        if let balance = data.balances.first(where: { $0.memberId == member.id }) {
            if balance.owes.isPositive {
                lines.append(String(localized: "You owe \(balance.owes.format()) so far, due by the \(ReminderLogic.ordinal(data.kameti.dueDay)).", bundle: .module))
            } else if balance.credit.isPositive {
                lines.append(String(localized: "You're ahead by \(balance.credit.format()).", bundle: .module))
            } else {
                lines.append(String(localized: "You're all paid up.", bundle: .module))
            }
        }
        if let turn = DetailLogic.nextTurn(
            for: member, kameti: data.kameti, from: data.current?.monthIndex ?? 1, slots: data.slots, shares: data.shares
        ) {
            let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: turn.monthIndex))
            lines.append(String(localized: "Your payout is in \(month): \(turn.payout.format()).", bundle: .module))
        }
        if let viewLink {
            lines.append(String(localized: "See everything any time: \(viewLink)", bundle: .module))
        }
        return lines.joined(separator: "\n")
    }
}
