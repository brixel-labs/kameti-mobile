import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

private func colorIndex(_ member: Member, _ members: [Member]) -> Int {
    Int(member.color ?? "") ?? max(members.firstIndex(of: member) ?? 0, 0)
}

/// Step 3 (AC-3): who is in. Invites go out after the kameti starts.
struct MembersStep: View {
    @Bindable var model: CreateWizardModel
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var submitted = false
    @State private var removing: Member?

    private var emailValid: Bool {
        let trimmed = newEmail.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || (trimmed.contains("@") && trimmed.contains(".") && !trimmed.contains(" "))
    }
    private var nameValid: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Who's in?", bundle: .module),
                        subtitle: String(localized: "Add everyone who pays. Invites go out after you start.", bundle: .module)
                    )
                    Toggle(isOn: Binding(
                        get: { model.selfMember != nil },
                        set: { included in Task { await model.setSelfMember(included: included) } }
                    )) {
                        Text("I'm also a member", bundle: .module).kText(KTextToken.bodyStrong)
                    }
                    .toggleStyle(KToggleStyle())
                    .disabled(model.isBusy)

                    KCard {
                        VStack(alignment: .leading, spacing: KSpace.md) {
                            Text("New person".uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                            WizardField(
                                title: String(localized: "Name", bundle: .module), text: $newName,
                                error: submitted && !nameValid ? String(localized: "Enter a name.", bundle: .module) : nil,
                                capitalization: .words
                            )
                            WizardField(
                                title: String(localized: "Email for the invite (optional)", bundle: .module), text: $newEmail,
                                error: submitted && !emailValid ? String(localized: "Enter a valid email, or leave it empty.", bundle: .module) : nil,
                                keyboard: .emailAddress, capitalization: .never
                            )
                            Button(action: add) {
                                Label(
                                    nameValid ? String(localized: "Add \(newName.trimmingCharacters(in: .whitespaces))", bundle: .module)
                                        : String(localized: "Add person", bundle: .module),
                                    systemImage: "person.badge.plus"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)
                            .disabled(model.isBusy)
                        }
                    }

                    if model.members.isEmpty {
                        ContentUnavailableView(
                            String(localized: "No one added yet", bundle: .module), systemImage: "person.2",
                            description: Text("Add the people who pay into this kameti.", bundle: .module)
                        )
                    } else {
                        Text(String(localized: "\(model.members.count) added", bundle: .module).uppercased())
                            .kText(KTextToken.label, color: KColors.textSecondary)
                        VStack(spacing: 0) {
                            ForEach(Array(model.members.enumerated()), id: \.element.id) { index, member in
                                memberRow(member, divider: index < model.members.count - 1)
                            }
                        }
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(primaryTitle: String(localized: "Next: slots", bundle: .module), isEnabled: !model.members.isEmpty, onBack: { model.back() }) {
                model.goTo(.slots)
            }
        }
        .alert(
            String(localized: "Remove this person?", bundle: .module), isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
            presenting: removing
        ) { member in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Remove", bundle: .module), role: .destructive) { Task { await model.removeMember(member.id) } }
        } message: { member in
            Text("\(member.name) will be taken out of this kameti. Slots they were in will need filling again.", bundle: .module)
        }
    }

    private func memberRow(_ member: Member, divider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                KAvatar(name: member.name, colorIndex: colorIndex(member, model.members), size: .medium)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.profileId != nil ? String(localized: "You (\(member.name))", bundle: .module) : member.name)
                        .kText(KTextToken.bodyStrong)
                    if member.profileId != nil {
                        Text("Owner", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    } else if model.emails[member.id] == nil {
                        Text("No email · can't get the app invite", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    } else if let email = model.emails[member.id] {
                        Text(email).kText(KTextToken.caption, color: KColors.textSecondary)
                    }
                }
                Spacer()
                if member.profileId == nil {
                    Button(role: .destructive) { removing = member } label: { Image(systemName: "trash") }
                        .accessibilityLabel(Text("Remove", bundle: .module))
                        .foregroundStyle(KColors.negative)
                }
            }
            .padding(.vertical, KSpace.md)
            if divider { Divider() }
        }
    }

    private func add() {
        submitted = true
        guard nameValid, emailValid else { return }
        let name = newName, email = newEmail
        newName = ""; newEmail = ""; submitted = false
        Task { await model.addMember(name: name, email: email) }
    }
}

/// Step 4 (AC-4): fill every slot, whole or split between up to four people.
struct SlotsStep: View {
    @Bindable var model: CreateWizardModel

    var body: some View {
        ZStack {
            if let slotId = model.editingSlotId, let slot = model.slots.first(where: { $0.id == slotId }) {
                SlotSplitView(model: model, slot: slot)
                    .transition(.move(edge: .trailing))
            } else {
                list
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.smooth(duration: 0.35), value: model.editingSlotId)
        .clipped()
    }

    private var list: some View {
        let checks = model.checks
        let slots = model.slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }
        let amount = model.slotAmount ?? .zero
        let ready = slots.count - checks.emptySlots.count - checks.badSlots.count
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Fill the \(slots.count) slots", bundle: .module),
                        subtitle: String(localized: "Each slot is \(amount.format()) a month. Give it to one person or share it between up to 4.", bundle: .module)
                    )
                    HStack {
                        Text("Slots ready", bundle: .module).kText(KTextToken.bodyStrong)
                        Spacer()
                        Text("\(ready) of \(slots.count)", bundle: .module).kText(KTextToken.bodyStrong, color: checks.passes ? KColors.positive : KColors.textSecondary)
                    }
                    if !checks.unassigned.isEmpty {
                        Label(
                            String(localized: "\(checks.unassigned.map(\.name).formatted(.list(type: .and))) not in any slot yet.", bundle: .module),
                            systemImage: "person.crop.circle.badge.exclamationmark"
                        )
                        .kText(KTextToken.bodySm, color: KColors.warning)
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
                    }
                    VStack(spacing: KSpace.sm) {
                        ForEach(slots) { slot in
                            Button { model.editingSlotId = slot.id } label: { slotRow(slot, amount: amount) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(primaryTitle: String(localized: "Next: payout order", bundle: .module), isEnabled: checks.slotsFilled && checks.slotsAddUp, onBack: { model.back() }) {
                model.goTo(.order)
            }
        }
    }

    private func slotRow(_ slot: Slot, amount: Money) -> some View {
        let active = PlanChecks.activeShares(of: slot.id, in: model.shares)
        let month = monthLabel(addingMonths(slot.payoutMonthIndex - 1, to: model.startMonth))
        let valid = PlanChecks.isValidSplit(active.map(\.monthlyAmount), slotAmount: amount)
        let byId = Dictionary(model.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return KCard {
            HStack {
                VStack(alignment: .leading, spacing: KSpace.xs) {
                    Text("Slot \(slot.payoutMonthIndex) · \(month)", bundle: .module).kText(KTextToken.bodyStrong)
                    if active.isEmpty {
                        Text("Tap to add people", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    } else if active.count == 1, valid {
                        Text("Whole slot · \(byId[active[0].memberId]?.name ?? "")", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    } else {
                        Text(active.map { "\(byId[$0.memberId]?.name ?? "") \($0.monthlyAmount.formatCompact())" }.joined(separator: " + "))
                            .kText(KTextToken.bodySm, color: KColors.textSecondary)
                        if !valid {
                            Text("\(PlanChecks.remaining(active.map(\.monthlyAmount), slotAmount: amount).format()) still to assign", bundle: .module)
                                .kText(KTextToken.caption, color: KColors.warning)
                        }
                    }
                }
                Spacer()
                if valid {
                    KPill(String(localized: "Ready", bundle: .module), symbol: "checkmark", foreground: KColors.positive, background: KColors.positiveSubtle)
                } else if active.isEmpty {
                    KPill(String(localized: "Empty", bundle: .module), symbol: "circle.dashed", foreground: KColors.textSecondary, background: KColors.surfaceSunken)
                }
                Image(systemName: "chevron.right").foregroundStyle(KColors.textTertiary)
            }
        }
    }
}

/// The split editor for one slot: who pays what each month.
struct SlotSplitView: View {
    @Bindable var model: CreateWizardModel
    let slot: Slot

    struct Line: Identifiable, Equatable {
        let id: String // member id
        var amountText: String
    }

    @State private var lines: [Line] = []
    @State private var seeded = false

    private var amount: Money { model.slotAmount ?? .zero }
    private var amounts: [Money] { lines.compactMap { Money(parsing: $0.amountText) } }
    private var remaining: Money { PlanChecks.remaining(amounts, slotAmount: amount) }
    private var valid: Bool { amounts.count == lines.count && PlanChecks.isValidSplit(amounts, slotAmount: amount) }

    private func slotCount(of member: Member) -> Int {
        Set(model.shares.filter { $0.memberId == member.id && $0.slotId != slot.id && $0.effectiveToMonth == nil }.map(\.slotId)).count
    }

    private var candidates: [Member] {
        model.members.filter { member in !lines.contains { $0.id == member.id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Who pays what each month?", bundle: .module),
                        subtitle: String(localized: "This slot needs \(amount.format()) a month. Up to 4 people.", bundle: .module)
                    )
                    Text("Slot \(slot.payoutMonthIndex) · \(monthLabel(addingMonths(slot.payoutMonthIndex - 1, to: model.startMonth)))", bundle: .module)
                        .kText(KTextToken.bodyStrong)
                    VStack(spacing: KSpace.sm) {
                        ForEach($lines) { $line in
                            if let member = model.members.first(where: { $0.id == line.id }) {
                                lineRow(member: member, line: $line)
                            }
                        }
                    }
                    if lines.count < 4 {
                        Menu {
                            if candidates.isEmpty {
                                Text("Everyone is already in this slot. Add more people in step 3.", bundle: .module)
                            }
                            ForEach(candidates) { member in
                                let count = slotCount(of: member)
                                let atLimit = count >= model.maxSlotsPerMember
                                Button {
                                    lines.append(Line(id: member.id, amountText: ""))
                                } label: {
                                    Text(atLimit ? "\(member.name) · already in \(count) slots, the limit" : "\(member.name) · in \(count) slots")
                                }
                                .disabled(atLimit)
                            }
                        } label: {
                            Label(String(localized: "Add a person", bundle: .module), systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    }
                    if !lines.isEmpty {
                        HStack {
                            if remaining.isZero {
                                Label(String(localized: "Adds up", bundle: .module), systemImage: "checkmark.circle")
                                    .kText(KTextToken.bodyStrong, color: KColors.positive)
                            } else if remaining.isNegative {
                                Text("Over by \(Money(-remaining.rupees).format())", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.negative)
                            } else {
                                Text("\(remaining.format()) still to assign", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.warning)
                            }
                            Spacer()
                            if lines.count >= 1, let even = PlanChecks.evenSplit(slotAmount: amount, count: lines.count) {
                                Button(String(localized: "Split evenly", bundle: .module)) {
                                    for index in lines.indices { lines[index].amountText = String(even[index].rupees) }
                                }
                                .buttonStyle(.glass)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(primaryTitle: String(localized: "Save slot", bundle: .module), isEnabled: valid, isLoading: model.isBusy) {
                let inputs = zip(lines, amounts).map { ShareInput(memberId: $0.id, monthlyAmount: $1) }
                Task { await model.saveSlotShares(slotId: slot.id, shares: inputs) }
            } secondary: {
                if !PlanChecks.activeShares(of: slot.id, in: model.shares).isEmpty {
                    Button(String(localized: "Empty this slot", bundle: .module), role: .destructive) {
                        Task { await model.saveSlotShares(slotId: slot.id, shares: []) }
                    }
                }
            }
        }
        .onAppear {
            guard !seeded else { return }
            seeded = true
            lines = PlanChecks.activeShares(of: slot.id, in: model.shares).map { Line(id: $0.memberId, amountText: String($0.monthlyAmount.rupees)) }
            // A fresh slot starts as a whole slot for the first person you add.
            if lines.isEmpty, model.members.count == 1, let only = model.members.first {
                lines = [Line(id: only.id, amountText: String(amount.rupees))]
            }
        }
        .onChange(of: lines.count) { _, count in
            // Adding the first person gives them the whole slot.
            if count == 1, lines[0].amountText.isEmpty { lines[0].amountText = String(amount.rupees) }
        }
    }

    private func lineRow(member: Member, line: Binding<Line>) -> some View {
        KCard {
            HStack(spacing: KSpace.md) {
                KAvatar(name: member.name, colorIndex: colorIndex(member, model.members), size: .medium)
                Text(member.name).kText(KTextToken.bodyStrong)
                Spacer()
                KAmountInput(digits: line.amountText, prompt: "Rs")
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
                    .padding(KSpace.sm)
                    .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: KRadius.input))
                Button(role: .destructive) { lines.removeAll { $0.id == member.id } } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(KColors.textTertiary)
                    .accessibilityLabel(Text("Remove", bundle: .module))
            }
        }
    }
}
