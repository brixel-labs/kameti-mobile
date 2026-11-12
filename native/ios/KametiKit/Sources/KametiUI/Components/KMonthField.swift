import SwiftUI

/// A month field that opens the month grid (board AP-2): one section per year,
/// three months a row, the chosen month filled green. Months outside
/// `months` are shown greyed out and can't be picked. Dates are UTC month starts.
public struct KMonthField: View {
    private let title: String
    private let months: [Date]
    /// The kameti's length, for "Runs Apr 2027 → Sep 2027 · 6 months".
    private let runLength: Int?
    @Binding private var selection: Date
    @State private var isOpen = false

    public init(_ title: String, selection: Binding<Date>, months: [Date], runLength: Int? = nil) {
        self.title = title; _selection = selection; self.months = months; self.runLength = runLength
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            Text(title).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            Button { kDismissKeyboard(); isOpen = true } label: {
                HStack {
                    Text(KMonthGrid.label(selection)).kText(KTextToken.body)
                    Spacer(minLength: KSpace.xs)
                    Image(systemName: "chevron.down").imageScale(.small).foregroundStyle(KColors.textSecondary)
                }
                .padding(.horizontal, KSpace.md)
                .frame(height: KSize.fieldHeight)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
                .contentShape(RoundedRectangle(cornerRadius: KRadius.input))
            }
            .buttonStyle(.plain)
        }
        .kBottomSheet(isPresented: $isOpen, title: title, detents: [.medium, .large]) {
            KMonthGrid(selection: $selection, months: months, runLength: runLength) { isOpen = false }
        }
    }
}

/// The sheet's content: years, each a 3-column grid of months.
struct KMonthGrid: View {
    @Binding var selection: Date
    let months: [Date]
    let runLength: Int?
    let onPick: () -> Void

    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .gmt
        return c
    }

    private var years: [Int] {
        Array(Set(months.map { Self.calendar.component(.year, from: $0) })).sorted()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(years, id: \.self) { year in
                        Text(verbatim: "\(year)")
                            .kText(KTextToken.bodyStrong)
                            .padding(.top, KSpace.lg).padding(.bottom, KSpace.sm).padding(.horizontal, KSpace.xxs)
                            .id(year)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(1...12, id: \.self) { month in
                                cell(Self.calendar.date(from: DateComponents(year: year, month: month, day: 1))!)
                            }
                        }
                    }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.bottom, KSpace.lg)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let runLength {
                    Text(String(localized: "Runs \(Self.shortLabel(selection)) → \(Self.shortLabel(Self.calendar.date(byAdding: .month, value: runLength - 1, to: selection) ?? selection)) · \(runLength) months", bundle: .module))
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, KSpace.xl).padding(.vertical, KSpace.md)
                        .background(KColors.background)
                }
            }
            .onAppear { proxy.scrollTo(Self.calendar.component(.year, from: selection), anchor: .top) }
        }
    }

    private func cell(_ month: Date) -> some View {
        let isOn = month == selection
        let allowed = months.contains(month)
        return Button {
            selection = month
            onPick()
        } label: {
            Text(month.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)))
                .kText(isOn ? KTextToken.bodyStrong : KTextToken.body,
                       color: isOn ? KColors.textOnBrand : (allowed ? KColors.textPrimary : KColors.textTertiary))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isOn ? KColors.brand : (allowed ? KColors.surface : KColors.surfaceSunken),
                            in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isOn ? KColors.brand : KColors.border))
                .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!allowed)
    }

    /// "April 2027".
    static func label(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: .gmt).month(.wide).year())
    }

    /// "Apr 2027".
    static func shortLabel(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated).year())
    }
}
