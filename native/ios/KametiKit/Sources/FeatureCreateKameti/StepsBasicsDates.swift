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
                        KAmountField(
                            String(localized: "Each slot pays per month", bundle: .module), digits: $model.amountText,
                            error: submitted && !model.slotAmountValid ? String(localized: "Enter an amount in steps of Rs 1,000.", bundle: .module) : nil
                        )
                        KFlowLayout {
                            ForEach(Self.suggestions, id: \.self) { value in
                                KChip(Money(value).formatCompact(), isOn: model.amountText == String(value)) { model.amountText = String(value) }
                            }
                        }
                    }
                    HStack(alignment: .top, spacing: KSpace.md) {
                        VStack(alignment: .leading, spacing: KSpace.xs) {
                            WizardLabel(String(localized: "Months (= slots)", bundle: .module))
                            KStepper(
                                value: model.months, range: WizardLimits.minMonths...WizardLimits.maxMonths,
                                decreaseLabel: String(localized: "Fewer months", bundle: .module),
                                increaseLabel: String(localized: "More months", bundle: .module),
                                onChange: { model.setMonths($0) }
                            )
                        }
                        KSelectField(
                            String(localized: "First month", bundle: .module), selection: $model.startMonth,
                            options: startOptions.map { (value: $0, label: monthLabel($0)) }
                        )
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
                        KFlowChips {
                            ForEach(Self.quickDays, id: \.self) { day in
                                KChip(ordinal(day), isOn: model.dueDay == day) { model.setDueDay(day) }
                            }
                            Menu {
                                Picker(String(localized: "Pick the due day", bundle: .module), selection: Binding(get: { model.dueDay }, set: model.setDueDay)) {
                                    ForEach(Array(WizardLimits.dueDays), id: \.self) { Text(ordinal($0)).tag($0) }
                                }
                            } label: {
                                KChip(Self.quickDays.contains(model.dueDay) ? String(localized: "Other", bundle: .module) : ordinal(model.dueDay),
                                     isOn: !Self.quickDays.contains(model.dueDay)) {}
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: KSpace.sm) {
                        WizardLabel(String(localized: "Remind on these days (tap to change)", bundle: .module))
                        KFlowChips {
                            ForEach(1...model.dueDay, id: \.self) { day in
                                KChip("\(day)", isOn: model.reminderDays.contains(day)) { model.toggleReminder(day) }
                                    .accessibilityLabel(Text("Remind on day \(day)", bundle: .module))
                            }
                        }
                        Text("At 10:00 AM, Pakistan time", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: KSpace.xs) {
                        WizardLabel(String(localized: "Most slots per person", bundle: .module))
                        KStepper(
                            value: model.maxSlotsPerMember, range: 1...WizardLimits.maxSlotsPerMember,
                            decreaseLabel: String(localized: "Fewer slots per person", bundle: .module),
                            increaseLabel: String(localized: "More slots per person", bundle: .module),
                            onChange: { model.setMaxSlots($0) }
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

/// Chips laid out in wrapping rows.
struct KFlowChips<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { KFlowLayout { content } }
}
