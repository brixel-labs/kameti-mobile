import KametiCore

/// The state of the slot split editor: who is in the slot and what each pays.
/// One person gets the whole amount; with more, amounts can be changed. Pure
/// logic, so the rules can be tested without a view.
struct SlotSplit: Equatable {
    struct Line: Equatable, Identifiable {
        let id: String // member id
        var amount: Money
    }

    static let maxPeople = 4
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

    /// The first person gets the whole slot. Anyone added after that starts at
    /// Rs 0: the owner sets their amount, and the others adjust (see `set`).
    mutating func add(_ id: String) {
        guard !isFull, !lines.contains(where: { $0.id == id }) else { return }
        lines.append(Line(id: id, amount: lines.isEmpty ? total : .zero))
    }

    /// The others keep their amounts, except that one person left gets the
    /// whole slot again.
    mutating func remove(_ id: String) {
        lines.removeAll { $0.id == id }
        if lines.count == 1 { lines[0].amount = total }
    }

    /// Even split in Rs 1,000 steps; the first person takes any remainder.
    mutating func splitEvenly() {
        if lines.count == 1 { lines[0].amount = total; return }
        guard let even = PlanChecks.evenSplit(slotAmount: total, count: lines.count) else { return }
        for index in lines.indices { lines[index].amount = even[index] }
    }

    /// The most one person can take, leaving Rs 1,000 for each other person.
    func ceiling(people: Int) -> Int { max(total.rupees - Self.unit * (people - 1), Self.unit) }

    /// Sets one person's amount (Rs 1,000 steps, never below Rs 1,000 or above
    /// what leaves Rs 1,000 for each other person); the rest of the slot is
    /// shared evenly by the others, so the total always stays the slot amount.
    mutating func set(_ id: String, to amount: Money) {
        guard let index = lines.firstIndex(where: { $0.id == id }), lines.count > 1 else { return }
        let value = min(max(amount.rupees / Self.unit * Self.unit, Self.unit), ceiling(people: lines.count))
        lines[index].amount = Money(value)
        let others = lines.indices.filter { $0 != index }
        guard let even = PlanChecks.evenSplit(slotAmount: Money(total.rupees - value), count: others.count) else { return }
        for (offset, otherIndex) in others.enumerated() { lines[otherIndex].amount = even[offset] }
    }

    mutating func nudge(_ id: String, by direction: Int) {
        guard let current = amount(of: id) else { return }
        set(id, to: Money(current.rupees + direction * Self.step(for: total)))
    }

    /// The size of a - or + tap, scaled to the slot amount.
    static func step(for total: Money) -> Int {
        total.rupees >= 200_000 ? 25_000 : total.rupees >= 50_000 ? 5_000 : unit
    }

    /// Preset amounts that fit with `people` people in the slot.
    static func presets(for total: Money, people: Int) -> [Money] {
        let ceiling = max(total.rupees - unit * (max(people, 1) - 1), unit)
        return [25_000, 50_000, 100_000, 150_000, 200_000].filter { $0 < total.rupees && $0 <= ceiling }.map(Money.init)
    }
}
