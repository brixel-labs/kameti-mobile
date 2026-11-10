import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Step 1 (AC-1): name, slot amount, months, first month and a live
/// "What this means" summary. Next creates or updates the draft.
struct BasicsStep: View {
    @Bindable var model: CreateWizardModel
    /// Errors show only after the first Next tap.
    @State private var submitted = false

    private static let suggestions = [50_000, 100_000, 250_000, 500_000]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "The basics", bundle: .module),
                        subtitle: String(localized: "You can change these until you start the kameti.", bundle: .module)
                    )
                    WizardField(
                        title: String(localized: "Kameti name", bundle: .module), text: $model.name,
                        error: submitted && !model.nameValid ? String(localized: "Use 3 to 40 characters.", bundle: .module) : nil,
                        helper: String(localized: "Members see this name.", bundle: .module),
                        capitalization: .words
                    )
                    VStack(alignment: .leading, spacing: KSpace.sm) {
                        WizardField(
                            title: String(localized: "Each slot pays per month", bundle: .module), text: $model.amountText,
                            prompt: "Rs",
                            error: submitted && !model.slotAmountValid ? String(localized: "Enter an amount in steps of Rs 1,000.", bundle: .module) : nil,
                            keyboard: .numberPad
                        )
                        HStack {
                            ForEach(Self.suggestions, id: \.self) { value in
                                Button(Money(value).formatCompact()) { model.amountText = String(value) }
                                    .buttonStyle(.glass)
                                    .controlSize(.small)
                            }
                        }
                    }
                    HStack(alignment: .top, spacing: KSpace.md) {
                        VStack(alignment: .leading, spacing: KSpace.xs) {
                            WizardLabel(String(localized: "Months (= slots)", bundle: .module))
                            WizardStepper(
                                value: model.months, range: WizardLimits.minMonths...WizardLimits.maxMonths,
                                decreaseLabel: String(localized: "Fewer months", bundle: .module),
                                increaseLabel: String(localized: "More months", bundle: .module),
                                onChange: model.setMonths
                            )
                        }
                        VStack(alignment: .leading, spacing: KSpace.xs) {
                            WizardLabel(String(localized: "First month", bundle: .module))
                            Picker("", selection: $model.startMonth) {
                                ForEach(startOptions, id: \.self) { Text(shortMonthLabel($0)).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, KSpace.xs)
                            .padding(.horizontal, KSpace.sm)
                            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                            .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
                        }
                    }
                    KCard {
                        VStack(alignment: .leading, spacing: KSpace.sm) {
                            Text("What this means".uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                            KeyValueRow(key: String(localized: "Pot each month", bundle: .module), value: model.pot.format(), emphasis: true)
                            KeyValueRow(key: String(localized: "One full slot pays in total", bundle: .module), value: model.pot.format())
                            KeyValueRow(
                                key: String(localized: "Runs", bundle: .module),
                                value: "\(shortMonthLabel(model.startMonth)) → \(shortMonthLabel(addingMonths(model.months - 1, to: model.startMonth)))"
                            )
                        }
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(
                primaryTitle: String(localized: "Next: due date", bundle: .module), isLoading: model.isBusy
            ) {
                submitted = true
                guard model.nameValid, model.slotAmountValid else { return }
                Task { await model.saveBasics() }
            }
        }
    }

    /// A year back to two years ahead, always including the chosen month.
    private var startOptions: [Date] {
        let current = KametiClock().currentMonth()
        var options = (-12...24).map { addingMonths($0, to: current) }
        if !options.contains(model.startMonth) { options.append(model.startMonth); options.sort() }
        return options
    }
}

/// Step 2 (AC-2): due day, reminder days and the most slots per person.
struct DatesStep: View {
    @Bindable var model: CreateWizardModel

    private static let quickDays = [1, 5, 10, 15, 20, 25]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Due date and reminders", bundle: .module),
                        subtitle: String(localized: "We'll nudge members who haven't paid. Paid members are never reminded.", bundle: .module)
                    )
                    VStack(alignment: .leading, spacing: KSpace.sm) {
                        WizardLabel(String(localized: "Members pay by", bundle: .module))
                        FlowChips {
                            ForEach(Self.quickDays, id: \.self) { day in
                                Chip(title: ordinal(day), isOn: model.dueDay == day) { model.setDueDay(day) }
                            }
                            Menu {
                                Picker(String(localized: "Pick the due day", bundle: .module), selection: Binding(get: { model.dueDay }, set: model.setDueDay)) {
                                    ForEach(Array(WizardLimits.dueDays), id: \.self) { Text(ordinal($0)).tag($0) }
                                }
                            } label: {
                                Chip(title: Self.quickDays.contains(model.dueDay) ? String(localized: "Other", bundle: .module) : ordinal(model.dueDay),
                                     isOn: !Self.quickDays.contains(model.dueDay)) {}
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: KSpace.sm) {
                        WizardLabel(String(localized: "Remind on these days (tap to change)", bundle: .module))
                        FlowChips {
                            ForEach(1...model.dueDay, id: \.self) { day in
                                Chip(title: "\(day)", isOn: model.reminderDays.contains(day)) { model.toggleReminder(day) }
                                    .accessibilityLabel(Text("Remind on day \(day)", bundle: .module))
                            }
                        }
                        Text("At 10:00 AM, Pakistan time", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: KSpace.xs) {
                        WizardLabel(String(localized: "Most slots per person", bundle: .module))
                        WizardStepper(
                            value: model.maxSlotsPerMember, range: 1...WizardLimits.maxSlotsPerMember,
                            decreaseLabel: String(localized: "Fewer slots per person", bundle: .module),
                            increaseLabel: String(localized: "More slots per person", bundle: .module),
                            onChange: model.setMaxSlots
                        )
                        Text("Up to \(WizardLimits.maxSlotsPerMember)", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(primaryTitle: String(localized: "Next: members", bundle: .module), isLoading: model.isBusy) {
                Task { await model.saveDates() }
            }
        }
    }
}

/// A pill that can be on or off.
struct Chip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .kText(KTextToken.bodyStrong, color: isOn ? KColors.textOnBrand : KColors.textPrimary)
                .padding(.horizontal, KSpace.md)
                .padding(.vertical, KSpace.sm)
                .background(isOn ? KColors.brand : KColors.surface, in: Capsule())
                .overlay(Capsule().stroke(isOn ? KColors.brand : KColors.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Wraps its children onto several lines.
struct FlowChips<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        FlowLayout(spacing: KSpace.sm) { content }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}
