import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// "Pay out November" (board AF · Record payout; FR-51 to FR-53, E20 to E23):
/// who receives the pot, how much each, any dues taken from a payout, and the
/// shortfall when the month wasn't fully collected.
struct PayoutSheet: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let monthIndex: Int
    let onDone: () -> Void

    @State private var draft: PayoutDraft
    @State private var payoutKeys: [String: String]
    @State private var deductionKeys: [String: String]
    @State private var paidDate: Date
    @State private var method = PaymentMethod.cash
    @State private var reference = ""
    @State private var note = ""
    @State private var showNoteError = false
    @State private var isBusy = false
    @State private var failure: Failure?
    /// The recipient whose amount is being typed (Custom).
    @State private var customId: String?
    @FocusState private var focused: String?

    init(data: KametiDetailData, model: KametiDetailViewModel, monthIndex: Int, onDone: @escaping () -> Void) {
        self.data = data
        self.model = model
        self.monthIndex = monthIndex
        self.onDone = onDone
        let row = data.collections.first { $0.monthIndex == monthIndex }
        let recipients = PayoutLogic.recipients(
            kameti: data.kameti, month: monthIndex, members: data.members, slots: data.slots, shares: data.shares,
            payouts: data.payouts, balances: data.balances, shortfall: row?.payoutShortfall ?? .zero
        )
        _draft = State(initialValue: PayoutDraft(recipients: recipients))
        _payoutKeys = State(initialValue: Dictionary(uniqueKeysWithValues: recipients.map { ($0.id, model.idempotencyKey) }))
        _deductionKeys = State(initialValue: Dictionary(uniqueKeysWithValues: recipients.map { ($0.id, model.idempotencyKey) }))
        _paidDate = State(initialValue: RecordPaymentSheet.localDate(from: data.today))
    }

    private var row: MonthCollectionRow? { data.collections.first { $0.monthIndex == monthIndex } }
    private var monthName: String { DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: monthIndex)).split(separator: " ").first.map(String.init) ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    if let row { summary(row) }
                    if let row, row.payoutShortfall.isPositive { shortfallBanner(row) }
                    if draft.recipients.isEmpty {
                        ContentUnavailableView(
                            String(localized: "No one to pay out", bundle: .module), systemImage: "person.slash",
                            description: Text("This month's slot has no one in it yet.", bundle: .module)
                        )
                    }
                    ForEach(draft.recipients) { recipient in recipientCard(recipient) }
                    if !draft.recipients.isEmpty {
                        Text("The shortfall is split by share. Change the amounts if you paid differently.", bundle: .module)
                            .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                    }
                    if draft.needsNote { noteField }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.bottom, KSpace.lg)
            }
            footer
        }
        .kDismissesKeyboard()
    }

    // MARK: Summary

    private func summary(_ row: MonthCollectionRow) -> some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.sm) {
                HStack {
                    Text("Collected", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                    Spacer()
                    KMoneyText(row.received, style: .title)
                }
                HStack {
                    Text("Full pot", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                    Spacer()
                    KMoneyText(row.target)
                }
                GeometryReader { proxy in
                    Capsule().fill(KColors.surfaceSunken).overlay(alignment: .leading) {
                        Capsule().fill(KColors.brand)
                            .frame(width: row.target.rupees > 0 ? proxy.size.width * min(CGFloat(row.received.rupees) / CGFloat(row.target.rupees), 1) : 0)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func shortfallBanner(_ row: MonthCollectionRow) -> some View {
        let owing = DetailLogic.owing(data.months, monthIndex: monthIndex).count
        return HStack(alignment: .top, spacing: KSpace.sm + 2) {
            Image(systemName: "exclamationmark.circle").foregroundStyle(KColors.warning)
            (Text("\(row.payoutShortfall.format()) short.", bundle: .module).fontWeight(.semibold)
                + Text(owing == 1
                       ? String(localized: " One member still owes it. You can pay out now; their dues stay on record.", bundle: .module)
                       : String(localized: " \(owing) members still owe it. You can pay out now; their dues stay on record.", bundle: .module)))
                .kText(KTextToken.bodySm, color: KColors.warning)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Recipients

    private func recipientCard(_ recipient: PayoutRecipient) -> some View {
        let total = draft.amount(recipient.id) + (draft.deduction(recipient.id) ?? .zero)
        let isPlanned = total == recipient.suggested
        let isFull = total == recipient.outstanding
        let isCustom = customId == recipient.id || (!isPlanned && !isFull)
        return VStack(alignment: .leading, spacing: KSpace.md) {
            HStack(spacing: KSpace.md) {
                KAvatar(name: recipient.member.name, colorIndex: recipient.colorIndex, size: .medium)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipient.member.id == data.me?.id ? String(localized: "You", bundle: .module) : recipient.member.name).kText(KTextToken.bodyStrong)
                    Text("Expected \(recipient.outstanding.format())", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                }
                Spacer(minLength: 0)
            }
            VStack(spacing: 2) {
                amountLabel(recipient)
                Text("paying now", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: KSpace.sm) {
                Spacer(minLength: 0)
                // "Planned" (less this person's part of the shortfall) only differs from
                // "Full" when the month was collected short.
                if recipient.suggested != recipient.outstanding {
                    KChip(String(localized: "Planned", bundle: .module), isOn: isPlanned && customId != recipient.id, style: .outlined) {
                        choose(recipient, recipient.suggested)
                    }
                }
                KChip(String(localized: "Full", bundle: .module), isOn: isFull && customId != recipient.id, style: .outlined) {
                    choose(recipient, recipient.outstanding)
                }
                KChip(String(localized: "Custom", bundle: .module), symbol: "pencil", isOn: isCustom, style: .outlined) {
                    withAnimation(.smooth(duration: 0.2)) { customId = recipient.id }
                    focused = recipient.id
                }
                Spacer(minLength: 0)
            }
            if recipient.owes.isPositive {
                Toggle(isOn: Binding(
                    get: { draft.deduction(recipient.id) != nil },
                    set: { draft.setDeduction(recipient.id, on: $0) }
                )) {
                    Text(draft.deduction(recipient.id).map { String(localized: "\($0.format()) is taken from \(firstName(recipient.member.name))'s payout and recorded as a payment.", bundle: .module) }
                         ?? String(localized: "\(firstName(recipient.member.name)) owes \(recipient.owes.format()). Take it from the payout?", bundle: .module))
                        .kText(KTextToken.bodySm)
                }
                .toggleStyle(KCheckboxStyle())
                .padding(KSpace.sm + 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KColors.background, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(KSpace.md)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(KColors.border))
    }

    /// The big amount: plain text, or editable in place (with "Rs" kept) once
    /// Custom is chosen.
    @ViewBuilder private func amountLabel(_ recipient: PayoutRecipient) -> some View {
        if customId == recipient.id {
            HStack(spacing: 6) {
                Text("Rs").kText(KTextStyle(size: 24, weight: .bold), color: KColors.textSecondary)
                KAmountInput(digits: digitsBinding(recipient.id), prompt: "0")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .multilineTextAlignment(.leading)
                    .focused($focused, equals: recipient.id)
                    .fixedSize()
            }
            .frame(minHeight: 40)
        } else {
            KMoneyText(draft.amount(recipient.id), style: .display)
                .frame(minHeight: 40)
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.2)) { customId = recipient.id }
                    focused = recipient.id
                }
        }
    }

    /// Picks a preset total, keeping any dues deduction on.
    private func choose(_ recipient: PayoutRecipient, _ target: Money) {
        kDismissKeyboard()
        withAnimation(.smooth(duration: 0.2)) {
            customId = nil
            let had = draft.deduction(recipient.id) != nil
            if had { draft.setDeduction(recipient.id, on: false) }
            draft.set(recipient.id, to: target)
            if had { draft.setDeduction(recipient.id, on: true) }
        }
    }

    private func digitsBinding(_ id: String) -> Binding<String> {
        Binding(
            get: { draft.amount(id).isZero ? "" : String(draft.amount(id).rupees) },
            set: { draft.set(id, to: Money(parsing: $0) ?? .zero) }
        )
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Note", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            TextField(String(localized: "Why does it differ? e.g. Hassan covered the shortfall", bundle: .module), text: $note)
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(showNoteError && note.trimmingCharacters(in: .whitespaces).isEmpty ? KColors.negative : KColors.border))
            Text("An amount that differs from what is expected needs a note.", bundle: .module)
                .kText(KTextToken.subtitleSmall, color: showNoteError && note.trimmingCharacters(in: .whitespaces).isEmpty ? KColors.negative : KColors.textSubtitle)
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: KSpace.md) {
            DateMethodBar(
                prefix: String(localized: "Paid", bundle: .module), date: $paidDate, method: $method, reference: $reference,
                today: data.today, earliest: data.kameti.startMonth
            )
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
            }
            Button(action: save) {
                ZStack {
                    Text("Mark paid out · \(draft.total.format())", bundle: .module).opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(!draft.hasAnything)
            .allowsHitTesting(!isBusy)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.vertical, KSpace.md)
        .background(KColors.background)
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        if draft.needsNote, trimmed.isEmpty { showNoteError = true; return }
        let ref = reference.trimmingCharacters(in: .whitespaces)
        let entries = draft.recipients.map {
            KametiDetailViewModel.PayoutEntry(slotId: $0.slotId, memberId: $0.id, amount: draft.amount($0.id), deduction: draft.deduction($0.id))
        }
        isBusy = true
        failure = nil
        Task {
            let result = await model.recordPayouts(
                entries, paidOn: RecordPaymentSheet.utcDate(from: paidDate), method: method,
                reference: method == .bankTransfer && !ref.isEmpty ? ref : nil, note: trimmed.isEmpty ? nil : trimmed,
                deductionNote: String(localized: "Taken from the month \(monthIndex) payout", bundle: .module),
                payoutKeys: payoutKeys, deductionKeys: deductionKeys
            )
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}
