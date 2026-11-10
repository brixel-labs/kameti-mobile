import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

private func colorIndex(_ member: Member, _ members: [Member]) -> Int {
    Int(member.color ?? "") ?? max(members.firstIndex(of: member) ?? 0, 0)
}

/// Step 3 (AC-3): who is in. Pick from "My people" (the owner's saved
/// contacts) or add someone new; anyone added is saved to My people for next
/// time. Invites go out after the kameti starts.
struct MembersStep: View {
    enum Mode { case fromPeople, newPerson }

    @Bindable var model: CreateWizardModel
    @State private var mode = Mode.newPerson
    @State private var chosenMode = false
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var search = ""
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
                    modeSwitch
                    Group {
                        switch mode {
                        case .newPerson: newPersonCard
                        case .fromPeople: peopleCard
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                    summaryRow
                    memberList
                }
                .padding(KSpace.xl)
                .animation(.smooth(duration: 0.3), value: mode)
                .animation(.smooth(duration: 0.3), value: model.members)
            }
            WizardFooter(
                primaryTitle: String(localized: "Next: slots", bundle: .module), isEnabled: !model.members.isEmpty,
                onBack: { model.back() }
            ) { model.goTo(.slots) }
        }
        .task {
            await model.loadContacts()
            // Start on My people only when there is someone saved to pick.
            if !chosenMode, !model.availableContacts.isEmpty { mode = .fromPeople }
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

    // MARK: Mode switch

    private var modeSwitch: some View {
        HStack(spacing: KSpace.md) {
            modeButton(.fromPeople, title: String(localized: "From my people", bundle: .module), symbol: "person.2")
            modeButton(.newPerson, title: String(localized: "Add new person", bundle: .module), symbol: "person.badge.plus")
        }
    }

    private func modeButton(_ target: Mode, title: String, symbol: String) -> some View {
        let isOn = mode == target
        return Button {
            chosenMode = true
            mode = target
        } label: {
            Label(title, systemImage: symbol)
                .kText(KTextToken.bodyStrong, color: isOn ? KColors.onBrandSubtle : KColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isOn ? KColors.brandSubtle : KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(isOn ? KColors.brand : KColors.border, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Add new person

    private var newPersonCard: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            Text("New person", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            PlainField(
                prompt: String(localized: "Name", bundle: .module), text: $newName,
                error: submitted && !nameValid ? String(localized: "Enter a name.", bundle: .module) : nil,
                capitalization: .words
            )
            PlainField(
                prompt: String(localized: "Email for the invite (optional)", bundle: .module), text: $newEmail,
                error: submitted && !emailValid ? String(localized: "Enter a valid email, or leave it empty.", bundle: .module) : nil,
                keyboard: .emailAddress, capitalization: .never
            )
            Button(action: add) {
                Text(nameValid ? String(localized: "Add \(firstName)", bundle: .module) : String(localized: "Add person", bundle: .module))
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(model.isBusy)
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.brand, lineWidth: 1.5))
    }

    private var firstName: String {
        newName.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? ""
    }

    // MARK: From my people

    private var peopleCard: some View {
        let list = model.availableContacts.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }
        return VStack(alignment: .leading, spacing: KSpace.md) {
            Text("My people", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            if model.contacts.isEmpty {
                emptyPeople(
                    title: String(localized: "No saved people yet", bundle: .module),
                    message: String(localized: "People you add to a kameti are saved here, so next time you can pick them.", bundle: .module)
                )
            } else if model.availableContacts.isEmpty {
                emptyPeople(
                    title: String(localized: "Everyone is already in", bundle: .module),
                    message: String(localized: "All your saved people are in this kameti. Add someone new instead.", bundle: .module)
                )
            } else {
                PlainField(prompt: String(localized: "Search", bundle: .module), text: $search, capitalization: .words)
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, contact in
                        Button { Task { await model.addMember(from: contact) } } label: {
                            HStack(spacing: KSpace.md) {
                                KAvatar(name: contact.name, colorIndex: contact.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 6, size: .medium)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name).kText(KTextToken.bodyStrong)
                                    Text(contact.email ?? String(localized: "No email", bundle: .module))
                                        .kText(KTextToken.caption, color: KColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(KColors.brand)
                            }
                            .padding(.vertical, KSpace.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isBusy)
                        if index < list.count - 1 { Divider() }
                    }
                }
            }
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.brand, lineWidth: 1.5))
    }

    private func emptyPeople(title: String, message: String) -> some View {
        VStack(spacing: KSpace.sm) {
            Text(title).kText(KTextToken.bodyStrong)
            Text(message).kText(KTextToken.bodySm, color: KColors.textSecondary).multilineTextAlignment(.center)
            Button(String(localized: "Add new person", bundle: .module)) { chosenMode = true; mode = .newPerson }
                .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KSpace.md)
    }

    // MARK: Added members

    private var summaryRow: some View {
        HStack {
            Text("\(model.members.count) added", bundle: .module)
                .kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                .contentTransition(.numericText(value: Double(model.members.count)))
            Spacer()
            Toggle(isOn: Binding(
                get: { model.selfMember != nil },
                set: { included in Task { await model.setSelfMember(included: included) } }
            )) {
                Text("I'm also a member", bundle: .module).kText(KTextToken.body)
            }
            .toggleStyle(KCheckboxStyle())
            .fixedSize()
            .disabled(model.isBusy)
        }
    }

    @ViewBuilder private var memberList: some View {
        if model.members.isEmpty {
            Text("Add the people who pay into this kameti.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KSpace.lg)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(model.members.enumerated()), id: \.element.id) { index, member in
                    memberRow(member, divider: index < model.members.count - 1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
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
                    } else if let email = model.emails[member.id] {
                        Text(email).kText(KTextToken.caption, color: KColors.textSecondary)
                    } else {
                        Text("No email · can't get the app invite", bundle: .module).kText(KTextToken.caption, color: KColors.warning)
                    }
                }
                Spacer()
                if member.profileId == nil {
                    Button { removing = member } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(KColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Remove", bundle: .module))
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

/// A bordered input with only a placeholder, for use inside a card.
struct PlainField: View {
    let prompt: String
    @Binding var text: String
    var error: String?
    var keyboard = UIKeyboardType.default
    var capitalization = TextInputAutocapitalization.sentences

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            TextField(prompt, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: KSize.fieldHeight)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(error == nil ? KColors.border : KColors.negative))
            if let error { Text(error).kText(KTextToken.caption, color: KColors.negative) }
        }
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
