import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Title and subtitle at the top of a step.
struct WizardHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            Text(title).kText(KTextToken.titleLg)
            Text(subtitle).kText(KTextToken.body, color: KColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small label above a control.
struct WizardLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
    }
}

/// "Step 2 of 6" with a segmented bar.
struct WizardProgress: View {
    let step: WizardStep

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            HStack(spacing: KSpace.xs) {
                ForEach(WizardStep.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue <= step.rawValue ? KColors.brand : KColors.border)
                        .frame(height: 4)
                }
            }
            Text("Step \(step.rawValue + 1) of \(WizardStep.allCases.count)", bundle: .module)
                .kText(KTextToken.caption, color: KColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The primary action pinned to the bottom of a step.
struct WizardFooter<Secondary: View>: View {
    let primaryTitle: String
    var isEnabled = true
    var isLoading = false
    let action: () -> Void
    @ViewBuilder var secondary: Secondary

    var body: some View {
        VStack(spacing: KSpace.sm) {
            Button(action: action) {
                ZStack {
                    Text(primaryTitle).opacity(isLoading ? 0 : 1)
                    if isLoading { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(!isEnabled)
            .allowsHitTesting(!isLoading)
            secondary
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.vertical, KSpace.md)
        .background(KColors.background)
    }
}

extension WizardFooter where Secondary == EmptyView {
    init(primaryTitle: String, isEnabled: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.init(primaryTitle: primaryTitle, isEnabled: isEnabled, isLoading: isLoading, action: action, secondary: { EmptyView() })
    }
}

/// A − value + control.
struct WizardStepper: View {
    let value: Int
    let range: ClosedRange<Int>
    let decreaseLabel: String
    let increaseLabel: String
    let onChange: (Int) -> Void

    var body: some View {
        HStack {
            Button { onChange(value - 1) } label: { Image(systemName: "minus") }
                .disabled(value <= range.lowerBound)
                .accessibilityLabel(decreaseLabel)
            Spacer()
            Text("\(value)").kText(KTextToken.title).monospacedDigit()
            Spacer()
            Button { onChange(value + 1) } label: { Image(systemName: "plus") }
                .disabled(value >= range.upperBound)
                .accessibilityLabel(increaseLabel)
        }
        .buttonStyle(.glass)
        .padding(KSpace.sm)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
        .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
    }
}

/// A text field with the wizard's look.
struct WizardField: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var error: String?
    var helper: String?
    var keyboard = UIKeyboardType.default
    var capitalization = TextInputAutocapitalization.sentences

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            WizardLabel(title)
            TextField(prompt, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(KSpace.md)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(error == nil ? KColors.border : KColors.negative))
            if let error {
                Text(error).kText(KTextToken.caption, color: KColors.negative)
            } else if let helper {
                Text(helper).kText(KTextToken.caption, color: KColors.textSecondary)
            }
        }
    }
}

/// "1st", "2nd", "3rd", "10th".
func ordinal(_ day: Int) -> String {
    let suffix: String
    switch (day % 100, day % 10) {
    case (11...13, _): suffix = "th"
    case (_, 1): suffix = "st"
    case (_, 2): suffix = "nd"
    case (_, 3): suffix = "rd"
    default: suffix = "th"
    }
    return "\(day)\(suffix)"
}

/// A key and value on one line inside a card.
struct KeyValueRow: View {
    let key: String
    let value: String
    var emphasis = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).kText(KTextToken.body, color: KColors.textSecondary)
            Spacer(minLength: KSpace.md)
            Text(value).kText(emphasis ? KTextToken.bodyStrong : KTextToken.body).multilineTextAlignment(.trailing)
        }
    }
}

/// "October 2026" for a date-only value.
func monthLabel(_ date: Date) -> String {
    date.formatted(Date.FormatStyle(timeZone: .gmt).month(.wide).year())
}

/// "Oct 2026".
func shortMonthLabel(_ date: Date) -> String {
    date.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated).year())
}

/// The month `offset` months after `date` (UTC).
func addingMonths(_ offset: Int, to date: Date) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar.date(byAdding: .month, value: offset, to: date) ?? date
}
