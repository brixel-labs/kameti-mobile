import Foundation
import KametiCore
import KametiDomain

/// One readable line of the activity log (FR-90), built from an audit entry.
struct ActivityItem: Identifiable, Equatable {
    enum Category: Hashable, CaseIterable { case money, members, changes }
    enum Tone: Equatable { case positive, negative, info, warning, neutral, brand }

    /// One field that changed in an edit: "Due day: 10th → 12th".
    struct Change: Equatable {
        let label: String
        let before: String
        let after: String
    }

    let id: Int
    let at: Date
    let category: Category
    let symbol: String
    let tone: Tone
    let title: String
    let detail: String?
    var changes: [Change] = []
}

/// Turns audit entries into activity rows, and the filters and grouping.
enum ActivityLogic {
    enum Filter: Hashable, CaseIterable { case all, money, members, changes }

    /// Names to show, from the kameti's current members plus what the entry
    /// itself remembers (a removed member is only in the entry).
    struct Context {
        let members: [Member]
        let slots: [Slot]
        let kameti: Kameti

        func name(_ id: String?, fallback: JSONValue? = nil) -> String {
            if let id, let member = members.first(where: { $0.id == id }) { return member.name }
            return fallback?["name"]?.stringValue ?? String(localized: "A member", bundle: .module)
        }

        func payoutLabel(slotId: String?) -> String? {
            guard let slot = slots.first(where: { $0.id == slotId }) else { return nil }
            let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: kameti, monthIndex: slot.payoutMonthIndex))
            return String(localized: "\(month.split(separator: " ").first.map(String.init) ?? month) payout", bundle: .module)
        }
    }

    static func item(_ entry: AuditEntry, _ c: Context) -> ActivityItem {
        let after = entry.after
        let before = entry.before
        let row = after ?? before
        let memberId = entry.memberId ?? row?["member_id"]?.stringValue
        let who = c.name(memberId, fallback: entry.entity == "member" ? row : nil)
        let amount = (row?["amount"]?.intValue).map { Money($0).format() }

        func make(_ category: ActivityItem.Category, _ symbol: String, _ tone: ActivityItem.Tone, _ title: String, _ detail: String?) -> ActivityItem {
            ActivityItem(id: entry.id, at: entry.at, category: category, symbol: symbol, tone: tone, title: title, detail: detail)
        }

        switch entry.action {
        case "payment.record":
            let method = methodName(after?["method"]?.stringValue)
            return make(.money, "checkmark", .positive, String(localized: "Payment recorded", bundle: .module),
                        [amount.map { String(localized: "\($0) from \(who)", bundle: .module) }, method].compactMap { $0 }.joined(separator: " · "))
        case "payment.void":
            let reason = after?["void_reason"]?.stringValue.map { "“\($0)”" }
            return make(.money, "nosign", .negative, String(localized: "Payment voided", bundle: .module),
                        [amount.map { String(localized: "\($0) from \(who)", bundle: .module) }, reason].compactMap { $0 }.joined(separator: " · "))
        case "payout.record":
            let month = c.payoutLabel(slotId: after?["slot_id"]?.stringValue)
            return make(.money, "arrow.up", .warning, month.map { String(localized: "\($0) paid out", bundle: .module) } ?? String(localized: "Payout recorded", bundle: .module),
                        amount.map { String(localized: "\($0) to \(who)", bundle: .module) })
        case "payout.void":
            let reason = after?["void_reason"]?.stringValue.map { "“\($0)”" }
            return make(.money, "nosign", .negative, String(localized: "Payout voided", bundle: .module),
                        [amount.map { String(localized: "\($0) to \(who)", bundle: .module) }, reason].compactMap { $0 }.joined(separator: " · "))

        case "member.add":
            return make(.members, "person.badge.plus", .brand, String(localized: "\(who) added", bundle: .module), nil)
        case "member.update":
            var item = make(.members, "pencil", .neutral, String(localized: "\(who)'s details changed", bundle: .module), nil)
            item.changes = changes(before, after, fields: [("name", String(localized: "Name", bundle: .module), text), ("nickname", String(localized: "Nickname", bundle: .module), text)])
            return item
        case "member.remove":
            return make(.members, "person.badge.minus", .negative, String(localized: "\(who) removed", bundle: .module), nil)
        case "member.approve_join", "invite.accept":
            return make(.members, "person.crop.circle.badge.checkmark", .info, String(localized: "\(who) joined", bundle: .module),
                        entry.action == "member.approve_join" ? String(localized: "Join request approved", bundle: .module) : String(localized: "Accepted the invite", bundle: .module))
        case "member.decline_join":
            return make(.members, "person.crop.circle.badge.xmark", .negative, String(localized: "\(who)'s join request rejected", bundle: .module), nil)
        case "member.unlink":
            return make(.members, "link", .neutral, String(localized: "\(who) unlinked from their account", bundle: .module), nil)
        case "invite.create":
            return make(.members, "envelope", .brand, String(localized: "Invite sent to \(who)", bundle: .module), after?["email"]?.stringValue)
        case "invite.revoke":
            return make(.members, "envelope.badge.shield.half.filled", .neutral, String(localized: "Invite to \(who) revoked", bundle: .module), nil)
        case "invite.accept_pending_approval":
            return make(.members, "person.badge.clock", .info, String(localized: "\(who) accepted with another email", bundle: .module),
                        String(localized: "Waiting for approval", bundle: .module))
        case "invite.decline":
            return make(.members, "xmark.circle", .neutral, String(localized: "\(who) declined the invite", bundle: .module), nil)

        case "kameti.create":
            return make(.changes, "sparkles", .brand, String(localized: "Kameti created", bundle: .module), nil)
        case "kameti.start":
            return make(.changes, "play.fill", .positive, String(localized: "Kameti started", bundle: .module), nil)
        case "kameti.update":
            var item = make(.changes, "pencil", .neutral, String(localized: "Kameti edited", bundle: .module), nil)
            item.changes = changes(before, after, fields: [
                ("name", String(localized: "Name", bundle: .module), text),
                ("description", String(localized: "Description", bundle: .module), text),
                ("due_day", String(localized: "Due day", bundle: .module), { $0?.intValue.map(EditKametiForm.ordinal) ?? "–" }),
                ("reminder_days", String(localized: "Reminders", bundle: .module), days),
            ])
            return item
        case "slot.set_shares":
            let label = c.payoutLabel(slotId: entry.entityId)
            return make(.changes, "chart.pie", .neutral,
                        label.map { String(localized: "Shares changed on the \($0)", bundle: .module) } ?? String(localized: "Slot shares changed", bundle: .module), nil)
        case "slot.reorder":
            return make(.changes, "arrow.up.arrow.down", .brand, String(localized: "Payout order changed", bundle: .module), nil)
        case "note.add", "note.update", "note.delete":
            let title = switch entry.action {
            case "note.add": String(localized: "Note added", bundle: .module)
            case "note.update": String(localized: "Note edited", bundle: .module)
            default: String(localized: "Note deleted", bundle: .module)
            }
            let body = row?["body"]?.stringValue.map { $0.count > 80 ? String($0.prefix(80)) + "…" : $0 }
            return make(.changes, "note.text", .neutral, title, body)
        default:
            return make(.changes, "clock", .neutral, entry.action.replacingOccurrences(of: ".", with: " ").capitalized, nil)
        }
    }

    // MARK: Fields

    private static func text(_ value: JSONValue?) -> String {
        guard let text = value?.stringValue, !text.isEmpty else { return String(localized: "None", bundle: .module) }
        return text
    }

    private static func days(_ value: JSONValue?) -> String {
        let list = value?.arrayValue?.compactMap(\.intValue).sorted() ?? []
        return list.isEmpty ? String(localized: "None", bundle: .module) : list.map(EditKametiForm.ordinal).joined(separator: ", ")
    }

    /// Only the listed fields that differ between before and after.
    static func changes(
        _ before: JSONValue?, _ after: JSONValue?, fields: [(key: String, label: String, format: (JSONValue?) -> String)]
    ) -> [ActivityItem.Change] {
        fields.compactMap { field in
            let old = before?[field.key], new = after?[field.key]
            guard old != new else { return nil }
            return ActivityItem.Change(label: field.label, before: field.format(old), after: field.format(new))
        }
    }

    private static func methodName(_ raw: String?) -> String? {
        switch raw {
        case "cash": String(localized: "cash", bundle: .module)
        case "bank": String(localized: "bank", bundle: .module)
        case "other": String(localized: "other", bundle: .module)
        default: nil
        }
    }

    // MARK: Lists

    static func items(_ entries: [AuditEntry], _ context: Context) -> [ActivityItem] {
        entries.sorted { ($0.at, $0.id) > ($1.at, $1.id) }.map { item($0, context) }
    }

    static func filtered(_ items: [ActivityItem], _ filter: Filter) -> [ActivityItem] {
        switch filter {
        case .all: items
        case .money: items.filter { $0.category == .money }
        case .members: items.filter { $0.category == .members }
        case .changes: items.filter { $0.category == .changes }
        }
    }

    /// Rows grouped by Pakistan calendar day, newest day first.
    static func byDay(_ items: [ActivityItem]) -> [(day: Date, items: [ActivityItem])] {
        var groups: [(day: Date, items: [ActivityItem])] = []
        for item in items {
            let day = DetailLogic.pakistanToday(item.at)
            if let last = groups.indices.last, groups[last].day == day { groups[last].items.append(item) } else { groups.append((day, [item])) }
        }
        return groups
    }

    /// "2:15 PM", Pakistan time.
    static func time(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "Asia/Karachi") ?? .gmt).hour().minute())
    }
}
