import Foundation
import KametiCore
import KametiDomain

/// The rules behind the Notes tab (FR-70 to FR-72), apart from the views so
/// they can be tested.
enum NoteLogic {
    enum Filter: Hashable, CaseIterable { case all, `private`, shared }

    /// What a note can be about from the composer: the kameti, a member, or a
    /// month's slot. (Payment and payout notes come from those items later.)
    struct Target: Hashable {
        let type: NoteTarget
        let id: String?
        let label: String
    }

    static func kametiTarget() -> Target {
        Target(type: .kameti, id: nil, label: String(localized: "Kameti", bundle: .module))
    }

    /// Members and slots to choose from, in schedule order.
    static func memberTargets(_ data: KametiDetailData) -> [Target] {
        data.members.map { Target(type: .member, id: $0.id, label: $0.name) }
    }

    static func slotTargets(_ data: KametiDetailData) -> [Target] {
        data.slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }.map {
            Target(type: .slot, id: $0.id, label: slotLabel($0, data))
        }
    }

    /// "October payout": a slot is named after the month it pays out.
    static func slotLabel(_ slot: Slot, _ data: KametiDetailData) -> String {
        let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: slot.payoutMonthIndex))
        let name = month.split(separator: " ").first.map(String.init) ?? month
        return String(localized: "\(name) payout", bundle: .module)
    }

    /// What the note is about, as shown after "@".
    static func targetLabel(_ note: Note, _ data: KametiDetailData) -> String {
        switch note.targetType {
        case .kameti:
            return String(localized: "Kameti", bundle: .module)
        case .member:
            return data.members.first { $0.id == note.targetId }?.name ?? String(localized: "A member", bundle: .module)
        case .slot:
            return data.slots.first { $0.id == note.targetId }.map { slotLabel($0, data) } ?? String(localized: "A slot", bundle: .module)
        case .payment:
            let payment = data.payments.first { $0.id == note.targetId }
            let who = payment.flatMap { p in data.members.first { $0.id == p.memberId }?.name }
            return who.map { String(localized: "Payment from \($0)", bundle: .module) } ?? String(localized: "A payment", bundle: .module)
        case .payout:
            let payout = data.payouts.first { $0.id == note.targetId }
            let who = payout.flatMap { p in data.members.first { $0.id == p.memberId }?.name }
            return who.map { String(localized: "Payout to \($0)", bundle: .module) } ?? String(localized: "A payout", bundle: .module)
        }
    }

    /// Notes for a filter and a search, newest first. The search matches the
    /// text and what the note is about.
    static func visible(_ notes: [Note], filter: Filter, search: String, data: KametiDetailData) -> [Note] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes
            .filter {
                switch filter {
                case .all: true
                case .private: $0.visibility == .private
                case .shared: $0.visibility == .shared
                }
            }
            .filter {
                query.isEmpty || $0.body.localizedCaseInsensitiveContains(query)
                    || targetLabel($0, data).localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    static func count(_ notes: [Note], _ filter: Filter) -> Int {
        switch filter {
        case .all: notes.count
        case .private: notes.filter { $0.visibility == .private }.count
        case .shared: notes.filter { $0.visibility == .shared }.count
        }
    }

    /// "Today", "Yesterday" or "3 Nov", by the Pakistan calendar day.
    static func dayText(_ date: Date, today: Date) -> String {
        let day = DetailLogic.pakistanToday(date)
        if day == today { return String(localized: "Today", bundle: .module) }
        if day.addingTimeInterval(86_400) == today { return String(localized: "Yesterday", bundle: .module) }
        return DetailLogic.dayMonth(day)
    }

}
