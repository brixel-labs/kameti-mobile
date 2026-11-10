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

    /// Adding the first person gives them the whole slot; each later person
    /// re-splits the slot evenly (the owner then adjusts).
    mutating func add(_ id: String) {
        guard !isFull, !lines.contains(where: { $0.id == id }) else { return }
        lines.append(Line(id: id, amount: .zero))
        splitEvenly()
    }

    /// The remaining people share the slot evenly again (one person gets the
    /// whole slot).
    mutating func remove(_ id: String) {
        lines.removeAll { $0.id == id }
        splitEvenly()
    }

    /// Even split in Rs 1,000 steps; the first person takes any remainder.
    mutating func splitEvenly() {
        if lines.count == 1 { lines[0].amount = total; return }
        guard let even = PlanChecks.evenSplit(slotAmount: total, count: lines.count) else { return }
        for index in lines.indices { lines[index].amount = even[index] }
    }

    /// Sets one person's amount, kept in Rs 1,000 steps and leaving at least
    /// Rs 1,000 for each other person.
    mutating func set(_ id: String, to amount: Money) {
        guard let index = lines.firstIndex(where: { $0.id == id }), lines.count > 1 else { return }
        let ceiling = total.rupees - Self.unit * (lines.count - 1)
        let clamped = min(max(amount.rupees / Self.unit * Self.unit, Self.unit), max(ceiling, Self.unit))
        lines[index].amount = Money(clamped)
    }

    mutating func nudge(_ id: String, by direction: Int) {
        guard let current = amount(of: id) else { return }
        set(id, to: Money(current.rupees + direction * Self.step(for: total)))
    }

    /// The size of a - or + tap, scaled to the slot amount.
    static func step(for total: Money) -> Int {
        total.rupees >= 200_000 ? 25_000 : total.rupees >= 50_000 ? 5_000 : unit
    }

    /// Preset amounts, only those that leave room for another person.
    static func presets(for total: Money) -> [Money] {
        [25_000, 50_000, 100_000, 150_000, 200_000]
            .filter { $0 + unit <= total.rupees }
            .map(Money.init)
    }
}
