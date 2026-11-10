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
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: KSpace.sm, trailing: 0))
                    HStack(spacing: KSpace.md) {
                        Button { withAnimation(.smooth) { order.shuffle() } } label: {
                            Label(String(localized: "Random draw", bundle: .module), systemImage: "shuffle").frame(maxWidth: .infinity)
                        }
                        Button { withAnimation(.smooth) { order = original } } label: {
                            Text("Same as slots", bundle: .module).frame(maxWidth: .infinity)
                        }
                    }
                    .kText(KTextToken.bodyStrong)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .listRowSeparator(.hidden)
                Section {
                    ForEach(Array(order.enumerated()), id: \.element) { index, slotId in
                        row(index: index, slotId: slotId)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onMove { order.move(fromOffsets: $0, toOffset: $1) }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, KSpace.xl)
            .environment(\.editMode, .constant(.active))
            .animation(.smooth, value: order)
            WizardFooter(primaryTitle: String(localized: "Next: review", bundle: .module), isLoading: model.isBusy, onBack: { model.back() }) {
                Task { await model.saveOrder(order) }
            }
        }
        .onAppear { if order.isEmpty { order = original } }
    }

    /// A month, who receives that month; the owner's own turn is tinted.
    private func row(index: Int, slotId: String) -> some View {
        let date = addingMonths(index, to: model.startMonth)
        let mine = PlanChecks.activeShares(of: slotId, in: model.shares).contains { $0.memberId == model.selfMember?.id }
        let names = names(of: slotId)
        return HStack(spacing: KSpace.md) {
            VStack(alignment: .leading, spacing: 0) {
                Text(date.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)).uppercased())
                    .kText(KTextToken.caption, color: mine ? KColors.onYourTurn : KColors.textSecondary)
                Text(date.formatted(Date.FormatStyle(timeZone: .gmt).year()))
                    .kText(KTextToken.bodyStrong, color: mine ? KColors.onYourTurn : KColors.textPrimary)
                    .monospacedDigit()
            }
            .frame(width: 52, alignment: .leading)
            Text(names).kText(KTextToken.body, color: mine ? KColors.onYourTurn : KColors.textPrimary).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, KSpace.md)
        .padding(.vertical, KSpace.sm + 2)
        .background(mine ? KColors.yourTurn : KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
        .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(mine ? KColors.yourTurnBorder : KColors.border))
        .accessibilityLabel(Text("Drag to move \(monthLabel(date))", bundle: .module))
    }

    private func names(of slotId: String) -> String {
        let me = model.selfMember?.id
        let byId = Dictionary(model.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let list = PlanChecks.activeShares(of: slotId, in: model.shares).compactMap { share -> String? in
            guard let member = byId[share.memberId] else { return nil }
            return member.id == me ? String(localized: "You", bundle: .module) : member.name
        }
        return list.isEmpty ? String(localized: "Empty", bundle: .module) : list.joined(separator: " + ")
    }
}

/// Step 6 (AC-6): a summary, the pre-start checks, then start or save as draft.
struct ReviewStep: View {
    @Bindable var model: CreateWizardModel
    let onStart: (String) -> Void
    let onSaveDraft: () -> Void
    // Emailing invites on start is shown as in the design; it isn't wired to
    // the invites backend yet, so the box does nothing until it is.
    @State private var emailInvites = true

    var body: some View {
        let checks = model.checks
        let amount = model.slotAmount ?? .zero
        let byId = Dictionary(model.members.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let first = model.slots.min { $0.payoutMonthIndex < $1.payoutMonthIndex }
        let firstNames = first.map { PlanChecks.activeShares(of: $0.id, in: model.shares).compactMap { byId[$0.memberId] } } ?? []
        let noEmail = model.members.filter { $0.profileId == nil && model.emails[$0.id] == nil }
        let withEmail = model.members.count(where: { $0.profileId == nil && model.emails[$0.id] != nil })
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(title: String(localized: "Ready to start?", bundle: .module), subtitle: "")
                        .padding(.bottom, -KSpace.lg)
                    summaryCard(amount: amount, firstNames: firstNames)
                    checksCard(checks: checks, amount: amount, noEmail: noEmail)
                    if withEmail > 0 {
                        Toggle(isOn: $emailInvites) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email invites to \(withEmail) people now", bundle: .module).kText(KTextToken.bodyStrong)
                                Text("You can also send them later from Members", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                            }
                        }
                        .toggleStyle(KCheckboxStyle())
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
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
                primaryTitle: String(localized: "Start kameti", bundle: .module), isEnabled: checks.passes, isLoading: model.isBusy,
                onBack: { model.back() }
            ) {
                Task { if let id = await model.start() { onStart(id) } }
            } secondary: {
                Button(String(localized: "Save draft", bundle: .module), action: onSaveDraft)
                    .kText(KTextToken.bodyStrong, color: KColors.onBrandSubtle)
            }
        }
    }

    private func summaryCard(amount: Money, firstNames: [String]) -> some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.sm) {
                HStack {
                    Text(model.name).kText(KTextToken.title)
                    Spacer()
                    Button(String(localized: "Edit", bundle: .module)) { model.goTo(.basics) }
                        .kText(KTextToken.bodyStrong, color: KColors.brand)
                }
                KeyValueRow(key: String(localized: "Pot each month", bundle: .module), value: model.pot.format(), emphasis: true)
                KeyValueRow(key: String(localized: "Slot amount", bundle: .module), value: String(localized: "\(amount.format()) / month", bundle: .module))
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
    }

    private func checksCard(checks: PlanChecks, amount: Money, noEmail: [Member]) -> some View {
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
                    ok: String(localized: "Everyone has a payout month", bundle: .module),
                    bad: String(localized: "Some slots don't have their own payout month", bundle: .module)
                )
                checkRow(
                    checks.withinLimit,
                    ok: String(localized: "No one is over \(model.maxSlotsPerMember) slots", bundle: .module),
                    bad: String(localized: "\(checks.overLimit.map(\.name).formatted(.list(type: .and))) over \(model.maxSlotsPerMember) slots", bundle: .module)
                )
                if !noEmail.isEmpty {
                    // A heads-up, not a blocker: they can still be added by link later.
                    let names = noEmail.map(\.name).formatted(.list(type: .and))
                    Label {
                        Text(noEmail.count == 1
                             ? String(localized: "\(names) has no email, so no app invite", bundle: .module)
                             : String(localized: "\(names) have no email, so no app invite", bundle: .module))
                            .kText(KTextToken.body, color: KColors.warning)
                    } icon: {
                        Image(systemName: "exclamationmark.circle").foregroundStyle(KColors.warning)
                    }
                }
            }
        }
    }

    private func checkRow(_ passes: Bool, ok: String, bad: String) -> some View {
        Label {
            Text(passes ? ok : bad).kText(KTextToken.body, color: passes ? KColors.textPrimary : KColors.warning)
        } icon: {
            Image(systemName: passes ? "checkmark" : "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(passes ? KColors.positive : KColors.warning)
        }
    }
}
