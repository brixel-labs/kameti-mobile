import KametiCore

/// The state of the slot split editor: who is in the slot and what each pays.
/// Every person starts at Rs 0 and the owner picks each amount from options
/// that fit in what is left, so the slot can never go over. Nothing is adjusted
/// on add, remove or when an amount changes; `remaining` shows what is left and
/// the slot can only be saved once it adds up. Pure logic, so the rules can be
/// tested without a view.
struct SlotSplit: Equatable {
    struct Line: Equatable, Identifiable {
        let id: String // member id
        var amount: Money
    }

    static let maxPeople = 3
    static let unit = 1_000

    let total: Money
    private(set) var lines: [Line]

    init(total: Money, lines: [Line] = []) {
        self.total = total
        self.lines = lines
    }

    var assigned: Money { lines.reduce(Money.zero) { $0 + $1.amount } }
    var remaining: Money { total - assigned }
    var isFull: Bool { lines.count >= Self.maxPeople }
    var isValid: Bool { PlanChecks.isValidSplit(lines.map(\.amount), slotAmount: total) }
    func amount(of id: String) -> Money? { lines.first { $0.id == id }?.amount }

    /// Someone still at less than Rs 1,000 (a newly added person).
    var hasUnset: Bool { lines.contains { $0.amount.rupees < Self.unit } }

    /// A new person starts at Rs 0; the owner picks their amount. Nobody else
    /// changes.
    mutating func add(_ id: String) {
        guard !isFull, !lines.contains(where: { $0.id == id }) else { return }
        lines.append(Line(id: id, amount: .zero))
    }

    /// Nobody else is changed: what was theirs becomes "left to assign".
    mutating func remove(_ id: String) {
        lines.removeAll { $0.id == id }
    }

    /// Someone can be added while part of the slot is unassigned and everyone
    /// already in has an amount.
    var canAdd: Bool { !isFull && !hasUnset && (lines.isEmpty || remaining.isPositive) }

    /// Even split in Rs 1,000 steps; the first person takes any remainder.
    mutating func splitEvenly() {
        if lines.count == 1 { lines[0].amount = total; return }
        guard let even = PlanChecks.evenSplit(slotAmount: total, count: lines.count) else { return }
        for index in lines.indices { lines[index].amount = even[index] }
    }

    /// The most this person can take: the slot minus what the others have.
    func ceiling(for id: String) -> Int {
        let others = lines.filter { $0.id != id }.reduce(0) { $0 + $1.amount.rupees }
        return max(total.rupees - others, Self.unit)
    }

    /// Sets one person's amount (Rs 1,000 steps, at least Rs 1,000, never more
    /// than what is left for them). Nobody else changes, so the slot can't
    /// go over.
    mutating func set(_ id: String, to amount: Money) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        let value = min(max(amount.rupees / Self.unit * Self.unit, Self.unit), ceiling(for: id))
        lines[index].amount = Money(value)
    }

    mutating func nudge(_ id: String, by direction: Int) {
        guard let current = amount(of: id) else { return }
        set(id, to: Money(current.rupees + direction * Self.step(for: total)))
    }

    /// The size of a - or + tap, scaled to the slot amount.
    static func step(for total: Money) -> Int {
        total.rupees >= 200_000 ? 25_000 : total.rupees >= 50_000 ? 5_000 : unit
    }

    /// Amounts the owner can pick for this person: a ladder scaled to the slot
    /// (25K, 50K, 1L ... up to a few lakh), only those that fit in what is left
    /// for them, plus the exact amount left so the slot can be completed.
    func options(for id: String) -> [Money] {
        let available = ceiling(for: id)
        let ladder = [25_000, 50_000, 100_000, 150_000, 200_000, 250_000, 300_000, 400_000, 500_000, 750_000, 1_000_000]
        var values = ladder.filter { $0 <= available && $0 <= total.rupees }
        if available % Self.unit == 0, available >= Self.unit, !values.contains(available) { values.append(available) }
        return values.sorted().map(Money.init)
    }
}
