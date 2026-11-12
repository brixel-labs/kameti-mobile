import Foundation
import KametiCore
import KametiDomain

/// The rules behind adding, editing and removing members, kept apart from the
/// views so they can be tested. They mirror the backend's `add_member`,
/// `update_member` and `remove_member`.
enum MemberLogic {
    /// Why a member can't be removed: what still ties them to the ledger.
    struct RemovalBlock: Equatable, Sendable {
        let slots: Int
        let payments: Int
    }

    /// `nil` when the member can be removed. Once a kameti has started, anyone
    /// who holds a share or has a payment or payout (voided ones count too)
    /// stays on the ledger, like the backend's `member_has_history`.
    static func removalBlock(for member: Member, in data: KametiDetailData) -> RemovalBlock? {
        guard data.kameti.status != .draft else { return nil }
        let holdsShares = data.shares.contains { $0.memberId == member.id }
        let payments = data.payments.filter { $0.memberId == member.id }.count
            + data.payouts.filter { $0.memberId == member.id }.count
        guard holdsShares || payments > 0 else { return nil }
        return RemovalBlock(slots: DetailLogic.slotCount(of: member, shares: data.shares), payments: payments)
    }

    /// Saved people who aren't in this kameti yet, by name.
    static func availableContacts(in data: KametiDetailData) -> [Contact] {
        let taken = Set(data.members.compactMap(\.contactId))
        return data.contacts.filter { !taken.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func contact(of member: Member, in data: KametiDetailData) -> Contact? {
        member.contactId.flatMap { id in data.contacts.first { $0.id == id } }
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 1–80 characters after trimming.
    static func isValidName(_ name: String) -> Bool {
        (1...80).contains(trimmed(name).count)
    }

    /// Empty is fine (the email is optional); otherwise a simple shape check.
    static func isValidEmail(_ email: String) -> Bool {
        let value = trimmed(email)
        guard !value.isEmpty else { return true }
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !parts[1].hasPrefix(".")
            && !parts[1].hasSuffix(".") && !value.contains(" ")
    }

    /// Empty is fine; otherwise digits with optional spaces, dashes and a
    /// leading +, 7 to 15 digits.
    static func isValidPhone(_ phone: String) -> Bool {
        let value = trimmed(phone)
        guard !value.isEmpty else { return true }
        let allowed = CharacterSet(charactersIn: "+0123456789 -")
        guard value.unicodeScalars.allSatisfy(allowed.contains), !value.dropFirst().contains("+") else { return false }
        return (7...15).contains(value.filter(\.isNumber).count)
    }

    /// The fields that changed, as `update_member` expects them: `nil` leaves
    /// a field alone and an empty string clears it. `nil` overall when
    /// nothing changed.
    static func changes(
        name: String, email: String, phone: String, from member: Member, contact: Contact?
    ) -> MemberChanges? {
        var changes = MemberChanges()
        if trimmed(name) != member.name { changes.name = trimmed(name) }
        if trimmed(email).lowercased() != (contact?.email ?? "").lowercased() { changes.email = trimmed(email) }
        if trimmed(phone) != (contact?.phone ?? "") { changes.phone = trimmed(phone) }
        return changes.name == nil && changes.email == nil && changes.phone == nil ? nil : changes
    }

    static func firstName(_ name: String) -> String {
        trimmed(name).split(separator: " ").first.map(String.init) ?? ""
    }
}
