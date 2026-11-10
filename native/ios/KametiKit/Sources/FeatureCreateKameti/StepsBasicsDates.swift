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

    private static let suggestions = [50_000, 100_000, 200_000, 250_000, 500_000]

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
    @State private var otherOpen = false
    // The overdue nudge and the owner summary are shown as in the design; the
    // backend has no fields for them yet, so they are not saved.
    @State private var overdueReminder = true
    @State private var ownerSummary = true

    private static let quickDays = [5, 10, 15]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Due date and reminders", bundle: .module),
                        subtitle: String(localized: "We'll nudge members who haven't paid. Paid members are never reminded.", bundle: .module)
                    )
                    dueDay
                    reminders
                    settingsCard
                    preview
                }
                .padding(KSpace.xl)
            }
            WizardFooter(
                primaryTitle: String(localized: "Next: members", bundle: .module), isLoading: model.isBusy,
                onBack: { model.back() }
            ) { Task { await model.saveDates() } }
        }
        .kBottomSheet(isPresented: $otherOpen, title: String(localized: "Pick the due day", bundle: .module), detents: [.medium, .large]) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(WizardLimits.dueDays), id: \.self) { day in
                        Button { withAnimation(.smooth(duration: 0.3)) { model.setDueDay(day) }; otherOpen = false } label: {
                            HStack {
                                Text(ordinal(day)).kText(KTextToken.body)
                                Spacer()
                                if model.dueDay == day { Image(systemName: "checkmark").foregroundStyle(KColors.brand) }
                            }
                            .padding(.horizontal, KSpace.xl)
                            .padding(.vertical, KSpace.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, KSpace.xl)
                    }
                }
            }
        }
    }

    private var dueDay: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            WizardLabel(String(localized: "Members pay by", bundle: .module))
            KFlowLayout {
                ForEach(Self.quickDays, id: \.self) { day in
                    KChip(ordinal(day), isOn: model.dueDay == day, style: .outlined) { withAnimation(.smooth(duration: 0.3)) { model.setDueDay(day) } }
                }
                let custom = !Self.quickDays.contains(model.dueDay)
                KChip(custom ? ordinal(model.dueDay) : String(localized: "Other", bundle: .module), isOn: custom, style: .outlined) {
                    otherOpen = true
                }
            }
        }
    }

    private var reminders: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            WizardLabel(String(localized: "Remind on these days (tap to change)", bundle: .module))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: KSpace.sm), count: 5), spacing: KSpace.sm) {
                ForEach(1...model.dueDay, id: \.self) { day in
                    KDayTile("\(day)", isOn: model.reminderDays.contains(day)) { model.toggleReminder(day) }
                        .accessibilityLabel(Text("Remind on day \(day)", bundle: .module))
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.3), value: model.dueDay)
            .animation(.smooth(duration: 0.2), value: model.reminderDays)
            HStack {
                Text("At", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                Spacer()
                Text("10:00 AM, Pakistan time", bundle: .module).kText(KTextToken.bodyStrong)
            }
            .padding(.horizontal, KSpace.md)
            .frame(minHeight: KSize.fieldHeight)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
            .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
        }
    }

    private var settingsCard: some View {
        KCard {
            VStack(spacing: 0) {
                toggleRow(
                    String(localized: "Overdue reminder", bundle: .module), String(localized: "Day after the due date", bundle: .module),
                    isOn: $overdueReminder
                )
                Divider().padding(.vertical, KSpace.md)
                toggleRow(
                    String(localized: "Tell me who hasn't paid", bundle: .module),
                    String(localized: "A summary for you on the \(ordinal(min(model.dueDay + 1, 28)))", bundle: .module),
                    isOn: $ownerSummary
                )
                Divider().padding(.vertical, KSpace.md)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Most slots per person", bundle: .module).kText(KTextToken.bodyStrong)
                        Text("Up to \(WizardLimits.maxSlotsPerMember)", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    }
                    Spacer()
                    KCompactStepper(
                        value: model.maxSlotsPerMember, range: 1...WizardLimits.maxSlotsPerMember,
                        decreaseLabel: String(localized: "Fewer slots per person", bundle: .module),
                        increaseLabel: String(localized: "More slots per person", bundle: .module),
                        onChange: { model.setMaxSlots($0) }
                    )
                }
            }
        }
    }

    private func toggleRow(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).kText(KTextToken.bodyStrong)
                Text(subtitle).kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
        }
        .toggleStyle(KToggleStyle())
    }

    /// What a member's reminder will look like.
    private var preview: some View {
        let amount = (model.slotAmount ?? .zero).format()
        let month = monthLabel(model.startMonth).split(separator: " ").first.map(String.init) ?? ""
        let owner = model.ownerName ?? String(localized: "your kameti owner", bundle: .module)
        return HStack(alignment: .top, spacing: KSpace.md) {
            Text("K").kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(width: 36, height: 36)
                .background(KColors.brand, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name.isEmpty ? String(localized: "Your kameti", bundle: .module) : model.name).kText(KTextToken.bodyStrong)
                Text("Reminder: \(amount) for \(month) is due by the \(ordinal(model.dueDay)). Pay \(owner).", bundle: .module)
                    .kText(KTextToken.body)
            }
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: KRadius.card))
        .animation(.smooth, value: model.dueDay)
    }
}

/// Chips laid out in wrapping rows.
struct KFlowChips<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { KFlowLayout { content } }
}
