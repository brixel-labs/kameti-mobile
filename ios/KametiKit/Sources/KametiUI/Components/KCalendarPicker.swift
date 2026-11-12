import SwiftUI

/// A month calendar for picking one day inside a range. Tapping a day, even
/// the one already selected, calls `onPick`, so a sheet can close on the tap.
/// Days outside the range are dimmed and not tappable.
public struct KCalendarPicker: View {
    @Binding private var selection: Date
    private let range: ClosedRange<Date>
    private let onPick: (Date) -> Void
    @State private var month: Date

    private let calendar = Calendar.current

    public init(selection: Binding<Date>, in range: ClosedRange<Date>, onPick: @escaping (Date) -> Void) {
        _selection = selection
        self.range = range
        self.onPick = onPick
        let cal = Calendar.current
        _month = State(initialValue: cal.date(from: cal.dateComponents([.year, .month], from: selection.wrappedValue)) ?? selection.wrappedValue)
    }

    public var body: some View {
        VStack(spacing: KSpace.md) {
            header
            weekdayRow
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day { dayCell(day) } else { Color.clear.frame(height: 44) }
                }
            }
        }
        // The same side padding as a sheet's title, so the month lines up with it.
        .padding(.horizontal, KSpace.xl)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text(month.formatted(.dateTime.month(.wide).year())).kText(KTextToken.bodyStrong)
            Spacer()
            arrow("chevron.left", enabled: canGo(-1)) { go(-1) }
            arrow("chevron.right", enabled: canGo(1)) { go(1) }
        }
    }

    private func arrow(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(enabled ? KColors.brand : KColors.textTertiary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func go(_ step: Int) {
        guard let next = calendar.date(byAdding: .month, value: step, to: month) else { return }
        withAnimation(.smooth(duration: 0.2)) { month = next }
    }

    private func canGo(_ step: Int) -> Bool {
        guard let next = calendar.date(byAdding: .month, value: step, to: month) else { return false }
        let key = calendar.dateComponents([.year, .month], from: next)
        let low = calendar.dateComponents([.year, .month], from: range.lowerBound)
        let high = calendar.dateComponents([.year, .month], from: range.upperBound)
        func value(_ c: DateComponents) -> Int { (c.year ?? 0) * 12 + (c.month ?? 0) }
        return value(key) >= value(low) && value(key) <= value(high)
    }

    // MARK: Days

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol).kText(KTextToken.label, color: KColors.textSecondary).frame(maxWidth: .infinity)
            }
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first]).map { $0.uppercased() }
    }

    /// The month's days, with blanks before the first one.
    private var cells: [Date?] {
        guard let days = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let lead = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: lead) + days.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private func dayCell(_ day: Date) -> some View {
        let enabled = calendar.startOfDay(for: day) >= calendar.startOfDay(for: range.lowerBound)
            && calendar.startOfDay(for: day) <= calendar.startOfDay(for: range.upperBound)
        let isSelected = calendar.isDate(day, inSameDayAs: selection)
        return Button {
            selection = day
            onPick(day)
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .kText(KTextToken.body, color: isSelected ? KColors.textOnBrand : (enabled ? KColors.textPrimary : KColors.textTertiary.opacity(0.6)))
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 44)
                .background { if isSelected { Circle().fill(KColors.brand).frame(width: 40, height: 40) } }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
