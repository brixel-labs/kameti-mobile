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

/// A segmented progress bar; the "Step 2 of 6" label sits in the navigation bar.
struct WizardProgress: View {
    let step: WizardStep

    var body: some View {
        HStack(spacing: KSpace.xs) {
            ForEach(WizardStep.allCases, id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? KColors.brand : KColors.border)
                    .frame(height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(step.rawValue + 1) of \(WizardStep.allCases.count)", bundle: .module))
    }
}

/// The actions pinned to the bottom of a step: a Back capsule beside the
/// primary capsule, or the primary alone on the first step.
struct WizardFooter<Secondary: View>: View {
    let primaryTitle: String
    var isEnabled = true
    var isLoading = false
    var onBack: (() -> Void)?
    var backTitle: String?
    var backIsDestructive = false
    let action: () -> Void
    @ViewBuilder var secondary: Secondary

    var body: some View {
        VStack(spacing: KSpace.sm) {
            HStack(spacing: KSpace.md) {
                if let onBack {
                    Button(action: onBack) {
                        Text(backTitle ?? String(localized: "Previous", bundle: .module))
                            .kText(KTextToken.bodyStrong, color: backIsDestructive ? KColors.negative : KColors.textPrimary)
                            .padding(.horizontal, KSpace.lg)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
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
            }
            secondary
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.vertical, KSpace.md)
        .background(KColors.background)
        // The glass buttons spring when their frame changes (the keyboard
        // hiding, say); keep the footer still.
        .transaction { $0.animation = nil }
    }
}

extension WizardFooter where Secondary == EmptyView {
    init(primaryTitle: String, isEnabled: Bool = true, isLoading: Bool = false, onBack: (() -> Void)? = nil, backTitle: String? = nil, backIsDestructive: Bool = false, action: @escaping () -> Void) {
        self.init(primaryTitle: primaryTitle, isEnabled: isEnabled, isLoading: isLoading, onBack: onBack, backTitle: backTitle, backIsDestructive: backIsDestructive, action: action, secondary: { EmptyView() })
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
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: KSize.fieldHeight)
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
