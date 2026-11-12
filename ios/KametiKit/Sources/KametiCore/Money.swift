import Foundation

/// An amount of Pakistani rupees. Always whole rupees (no paisa).
///
/// Never use `Double` for money in this app. Every amount on screen goes
/// through `Money` and its formatting (`format()` / `KMoneyText`).
public struct Money: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let rupees: Int

    public init(_ rupees: Int) {
        self.rupees = rupees
    }

    public static let zero = Money(0)

    /// Parses user input such as `"2,50,000"` or `"250000"`. Returns `nil` for
    /// empty text or anything that isn't a whole number.
    public init?(parsing input: String) {
        let digits = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !digits.isEmpty, let value = Int(digits) else { return nil }
        self.init(value)
    }

    public var isZero: Bool { rupees == 0 }
    public var isNegative: Bool { rupees < 0 }
    public var isPositive: Bool { rupees > 0 }

    public static func + (lhs: Money, rhs: Money) -> Money { Money(lhs.rupees + rhs.rupees) }
    public static func - (lhs: Money, rhs: Money) -> Money { Money(lhs.rupees - rhs.rupees) }
    public static func * (lhs: Money, rhs: Int) -> Money { Money(lhs.rupees * rhs) }
    public static prefix func - (value: Money) -> Money { Money(-value.rupees) }
    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.rupees < rhs.rupees }

    public func abs() -> Money { Money(Swift.abs(rupees)) }

    /// Whether this is a multiple of the positive `step` (for example the
    /// Rs 1,000 steps a slot share must use).
    public func isMultiple(of step: Money) -> Bool {
        step.rupees > 0 && rupees % step.rupees == 0
    }

    // MARK: Codable (a bare integer, like Postgres `bigint`)

    public init(from decoder: any Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(Int.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rupees)
    }

    // MARK: Formatting

    /// Lakh/crore grouping: `Rs 24,00,000`. Without the symbol: `24,00,000`.
    public func format(symbol: Bool = true) -> String {
        let grouped = Self.groupIndian(Swift.abs(rupees))
        let sign = rupees < 0 ? "−" : ""
        return symbol ? "\(sign)Rs \(grouped)" : "\(sign)\(grouped)"
    }

    /// Compact form for tight spaces: `50K`, `1.25 L`, `2.4 Cr`.
    public func formatCompact() -> String {
        let n = Swift.abs(rupees)
        let sign = rupees < 0 ? "−" : ""
        if n >= 10_000_000 { return "\(sign)\(Self.trimmed(n, per: 10_000_000)) Cr" }
        if n >= 100_000 { return "\(sign)\(Self.trimmed(n, per: 100_000)) L" }
        if n >= 1_000 { return "\(sign)\(Self.trimmed(n, per: 1_000))K" }
        return "\(sign)\(n)"
    }

    public var description: String { format() }

    /// `n / divisor` to at most two decimals without trailing zeros, using
    /// integer arithmetic only (round half up).
    private static func trimmed(_ n: Int, per divisor: Int) -> String {
        let hundredths = (n * 100 + divisor / 2) / divisor
        let whole = hundredths / 100
        let fraction = hundredths % 100
        if fraction == 0 { return "\(whole)" }
        var digits = fraction < 10 ? "0\(fraction)" : "\(fraction)"
        if digits.hasSuffix("0") { digits.removeLast() }
        return "\(whole).\(digits)"
    }

    private static func groupIndian(_ value: Int) -> String {
        let digits = String(value)
        guard digits.count > 3 else { return digits }
        let last3 = String(digits.suffix(3))
        var rest = String(digits.dropLast(3))
        var parts: [String] = []
        while rest.count > 2 {
            parts.insert(String(rest.suffix(2)), at: 0)
            rest = String(rest.dropLast(2))
        }
        if !rest.isEmpty { parts.insert(rest, at: 0) }
        return parts.joined(separator: ",") + "," + last3
    }
}
