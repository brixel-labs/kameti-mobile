import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Step 5 (AC-5): who gets the pot when. Drag to reorder.
struct OrderStep: View {
    @Bindable var model: CreateWizardModel
    @State private var order: [String] = []

    private var original: [String] { model.slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }.map(\.id) }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    WizardHeading(
                        title: String(localized: "Who gets the pot when?", bundle: .module),
                        subtitle: String(localized: "Hold and drag to reorder. Members will see this order.", bundle: .module)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    HStack {
                        Button { order.shuffle() } label: { Label(String(localized: "Random draw", bundle: .module), systemImage: "shuffle") }
                        Button { order = original } label: { Label(String(localized: "Same as slots", bundle: .module), systemImage: "arrow.uturn.backward") }
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section {
                    ForEach(Array(order.enumerated()), id: \.element) { index, slotId in
                        HStack {
                            Text(monthLabel(addingMonths(index, to: model.startMonth))).kText(KTextToken.bodyStrong)
                            Spacer()
                            Text(names(of: slotId)).kText(KTextToken.body, color: KColors.textSecondary).lineLimit(1)
                        }
                        .accessibilityLabel(Text("Drag to move \(monthLabel(addingMonths(index, to: model.startMonth)))", bundle: .module))
                    }
                    .onMove { order.move(fromOffsets: $0, toOffset: $1) }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
            WizardFooter(primaryTitle: String(localized: "Next: review", bundle: .module), isLoading: model.isBusy) {
                Task { await model.saveOrder(order) }
            }
        }
        .onAppear { if order.isEmpty { order = original } }
    }

    private func names(of slotId: String) -> String {
        let byId = Dictionary(model.members.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let list = PlanChecks.activeShares(of: slotId, in: model.shares).compactMap { byId[$0.memberId] }
        return list.isEmpty ? String(localized: "Empty", bundle: .module) : list.joined(separator: " + ")
    }
}

/// Step 6 (AC-6): a summary, the pre-start checks, then start or save as draft.
struct ReviewStep: View {
    @Bindable var model: CreateWizardModel
    let onStart: (String) -> Void
    let onSaveDraft: () -> Void

    var body: some View {
        let checks = model.checks
        let amount = model.slotAmount ?? .zero
        let first = model.slots.min { $0.payoutMonthIndex < $1.payoutMonthIndex }
        let byId = Dictionary(model.members.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let firstNames = first.map { PlanChecks.activeShares(of: $0.id, in: model.shares).compactMap { byId[$0.memberId] } } ?? []
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(title: String(localized: "Ready to start?", bundle: .module), subtitle: model.name)
                    KCard {
                        VStack(alignment: .leading, spacing: KSpace.sm) {
                            KeyValueRow(key: String(localized: "Slot amount", bundle: .module), value: String(localized: "\(amount.format()) / month", bundle: .module))
                            KeyValueRow(key: String(localized: "Pot each month", bundle: .module), value: model.pot.format(), emphasis: true)
                            KeyValueRow(
                                key: String(localized: "Runs", bundle: .module),
                                value: String(localized: "\(shortMonthLabel(model.startMonth)) → \(shortMonthLabel(addingMonths(model.months - 1, to: model.startMonth))) · \(model.months) months", bundle: .module)
                            )
                            KeyValueRow(key: String(localized: "Members", bundle: .module), value: String(localized: "\(model.members.count) people", bundle: .module))
                            KeyValueRow(
                                key: String(localized: "Due by", bundle: .module),
                                value: model.reminderDays.isEmpty
                                    ? String(localized: "\(ordinal(model.dueDay)) · no reminders", bundle: .module)
                                    : String(localized: "\(ordinal(model.dueDay)) · reminders \(model.reminderDays.map(String.init).joined(separator: ", "))", bundle: .module)
                            )
                            KeyValueRow(
                                key: String(localized: "First payout", bundle: .module),
                                value: firstNames.isEmpty ? String(localized: "Not set yet", bundle: .module)
                                    : "\(firstNames.joined(separator: " + ")) · \(shortMonthLabel(model.startMonth))"
                            )
                        }
                    }
                    KCard {
                        VStack(alignment: .leading, spacing: KSpace.md) {
                            Text("Checks".uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                            checkRow(
                                checks.slotsFilled,
                                ok: String(localized: "All \(model.slots.count) slots are filled", bundle: .module),
                                bad: String(localized: "\(checks.emptySlots.count) slots are empty", bundle: .module)
                            )
                            checkRow(
                                checks.slotsAddUp,
                                ok: String(localized: "Every slot adds up to \(amount.format())", bundle: .module),
                                bad: String(localized: "\(checks.badSlots.count) slots don't add up to \(amount.format())", bundle: .module)
                            )
                            checkRow(
                                Set(model.slots.map(\.payoutMonthIndex)).count == model.slots.count,
                                ok: String(localized: "Every slot has its own payout month", bundle: .module),
                                bad: String(localized: "Some slots don't have their own payout month", bundle: .module)
                            )
                            checkRow(
                                checks.withinLimit,
                                ok: String(localized: "No one is over \(model.maxSlotsPerMember) slots", bundle: .module),
                                bad: String(localized: "\(checks.overLimit.map(\.name).formatted(.list(type: .and))) over \(model.maxSlotsPerMember) slots", bundle: .module)
                            )
                        }
                    }
                    Text("Once started, the slot amount and number of months can't change. You can still edit members, notes and future payout months.", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    if !checks.passes {
                        Label(String(localized: "Fix the checks above before starting.", bundle: .module), systemImage: "exclamationmark.triangle")
                            .kText(KTextToken.bodySm, color: KColors.warning)
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(
                primaryTitle: String(localized: "Start kameti", bundle: .module), isEnabled: checks.passes, isLoading: model.isBusy
            ) {
                Task { if let id = await model.start() { onStart(id) } }
            } secondary: {
                Button(String(localized: "Save draft", bundle: .module), action: onSaveDraft)
                    .buttonStyle(.glass)
                    .controlSize(.large)
            }
        }
    }

    private func checkRow(_ passes: Bool, ok: String, bad: String) -> some View {
        Label {
            Text(passes ? ok : bad).kText(KTextToken.body, color: passes ? KColors.textPrimary : KColors.warning)
        } icon: {
            Image(systemName: passes ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(passes ? KColors.positive : KColors.warning)
        }
    }
}
