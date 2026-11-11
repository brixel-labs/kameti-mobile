import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Record payment (board A · Record payment): who paid, how much, when and how.
/// The amount can be filled with what is left or the full month.
struct RecordPaymentSheet: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    var preselected: String?
    let onDone: () -> Void

    @State private var memberId: String?
    @State private var digits = ""
    @State private var dateChoice = DateChoice.today
    @State private var customDate: Date
    @State private var method = PaymentMethod.cash
    @State private var reference = ""
    @State private var note = ""
    @State private var pickingMember = false
    @State private var isBusy = false
    @State private var failure: Failure?
    @State private var key: String

    init(data: KametiDetailData, model: KametiDetailViewModel, preselected: String?, onDone: @escaping () -> Void) {
        self.data = data
        self.model = model
        self.preselected = preselected
        self.onDone = onDone
        let first = preselected ?? PaymentLogic.payers(in: data).first { (PaymentLogic.monthRow(for: $0.id, in: data)?.remaining.isPositive) ?? false }?.id
        _memberId = State(initialValue: first)
        _customDate = State(initialValue: Self.localDate(from: data.today))
        _key = State(initialValue: model.idempotencyKey)
        if let first, let remaining = PaymentLogic.monthRow(for: first, in: data)?.remaining, remaining.isPositive {
            _digits = State(initialValue: String(remaining.rupees))
        }
    }

    private var receivedOn: Date { dateChoice.date(today: data.today, custom: customDate) }

    private var member: Member? { data.members.first { $0.id == memberId } }
    private var row: MemberMonthRow? { memberId.flatMap { PaymentLogic.monthRow(for: $0, in: data) } }
    private var amount: Money { Money(parsing: digits) ?? .zero }
    private var monthName: String { data.current.map { DetailLogic.monthTitle($0.monthStart).split(separator: " ").first.map(String.init) ?? "" } ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                memberField
                amountField
                ReceivedDateChooser(choice: $dateChoice, custom: $customDate, today: data.today, earliest: data.kameti.startMonth)
                MethodChooser(method: $method, reference: $reference)
                VStack(alignment: .leading, spacing: 6) {
                    label(String(localized: "Note (optional)", bundle: .module))
                    TextField(String(localized: "e.g. Meezan transfer, ref 88213", bundle: .module), text: $note)
                        .padding(.horizontal, KSpace.md)
                        .frame(minHeight: 48)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.border))
                }
                outcomeBanner
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                        .kText(KTextToken.bodySm, color: KColors.negative)
                }
                Button(action: submit) {
                    ZStack {
                        Text("Record \(amount.format())", bundle: .module).opacity(isBusy ? 0 : 1)
                        if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                    }
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(KColors.brand)
                .controlSize(.large)
                .disabled(!amount.isPositive || memberId == nil)
                .allowsHitTesting(!isBusy)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
        .kBottomSheet(isPresented: $pickingMember, title: String(localized: "Choose a member", bundle: .module), detents: [.medium, .large]) {
            MemberPickerList(data: data, selected: memberId) { id in
                memberId = id
                if let remaining = PaymentLogic.monthRow(for: id, in: data)?.remaining, remaining.isPositive { digits = String(remaining.rupees) }
                pickingMember = false
            }
        }
    }

    // MARK: Pieces

    private func label(_ text: String) -> some View {
        Text(text).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
    }

    private var memberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label(String(localized: "Member", bundle: .module))
            Button { kDismissKeyboard(); pickingMember = true } label: {
                HStack(spacing: KSpace.md) {
                    if let member {
                        KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members), size: .medium)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name).kText(KTextToken.bodyStrong)
                            if let row {
                                Text("Due \(row.due.format()) · paid \(row.allocated.format())", bundle: .module)
                                    .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                            }
                        }
                    } else {
                        Text("Choose a member", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(KColors.textSecondary)
                }
                .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.border))
                // The whole card is the button, not just the arrow.
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Amount received", bundle: .module))
            HStack(spacing: KSpace.sm) {
                Text("Rs").kText(KTextStyle(size: 20, weight: .semibold), color: KColors.textSecondary)
                KAmountInput(digits: $digits, prompt: "0")
                    .font(.system(size: 26, weight: .bold))
                    .monospacedDigit()
            }
            .padding(.horizontal, KSpace.lg)
            .frame(height: 60)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.brand, lineWidth: 2))
            if let row, row.due.isPositive {
                // Quick amounts from this member's month: what they still owe
                // (only when they have paid part of it) and the full month.
                KFlowLayout {
                    if row.remaining.isPositive, row.remaining != row.due {
                        KChip(String(localized: "Remaining \(row.remaining.format(symbol: false))", bundle: .module), isOn: amount == row.remaining, style: .outlined) {
                            digits = String(row.remaining.rupees)
                        }
                    }
                    KChip(String(localized: "Full month \(row.due.format(symbol: false))", bundle: .module), isOn: amount == row.due, style: .outlined) {
                        digits = String(row.due.rupees)
                    }
                }
            }
        }
    }

    @ViewBuilder private var outcomeBanner: some View {
        let name = member.map { firstName($0.name) } ?? ""
        switch PaymentLogic.outcome(amount: amount, row: row) {
        case .none:
            EmptyView()
        case .fullyPaid:
            banner(String(localized: "\(name) will be fully paid for \(monthName).", bundle: .module), symbol: "checkmark", fg: KColors.positive, bg: KColors.positiveSubtle)
        case .stillOwes(let left):
            banner(String(localized: "\(name) will still owe \(left.format()) for \(monthName).", bundle: .module), symbol: "clock", fg: KColors.warning, bg: KColors.warningSubtle)
        case .credit(let extra):
            banner(String(localized: "\(extra.format()) extra becomes credit for later months.", bundle: .module), symbol: "plus.circle", fg: KColors.info, bg: KColors.infoSubtle)
        }
    }

    private func banner(_ text: String, symbol: String, fg: Color, bg: Color) -> some View {
        Label(text, systemImage: symbol)
            .kText(KTextToken.bodySm, color: fg)
            .padding(KSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg, in: RoundedRectangle(cornerRadius: 12))
    }

    private func submit() {
        guard let memberId, amount.isPositive else { return }
        isBusy = true
        failure = nil
        let received = receivedOn
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        let ref = reference.trimmingCharacters(in: .whitespaces)
        Task {
            let result = await model.recordPayment(
                memberId: memberId, amount: amount, receivedOn: received, method: method,
                reference: method == .bankTransfer && !ref.isEmpty ? ref : nil,
                note: trimmed.isEmpty ? nil : trimmed, idempotencyKey: key
            )
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }

    // The picker works in local calendar days; the backend takes a date-only value.
    /// Days the owner can pick: from the kameti's first day to today (never an
    /// empty range, even if the phone's date is before the kameti started).
    static func pickableRange(from earliest: Date, to today: Date) -> ClosedRange<Date> {
        let end = localDate(from: today)
        return min(localDate(from: earliest), end)...end
    }

    static func localDate(from utcDay: Date) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let parts = utc.dateComponents([.year, .month, .day], from: utcDay)
        return Calendar.current.date(from: parts) ?? utcDay
    }

    static func utcDate(from local: Date) -> Date {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: local)
        return DateOnly.make(year: parts.year ?? 2026, month: parts.month ?? 1, day: parts.day ?? 1)
    }
}

/// The members to pick from, with what each still owes this month.
struct MemberPickerList: View {
    let data: KametiDetailData
    let selected: String?
    let onPick: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(PaymentLogic.payers(in: data)) { member in
                    let row = PaymentLogic.monthRow(for: member.id, in: data)
                    Button { onPick(member.id) } label: {
                        HStack(spacing: KSpace.md) {
                            KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members), size: .medium)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(member.name).kText(KTextToken.bodyStrong)
                                if let row {
                                    Text(row.remaining.isPositive ? String(localized: "Owes \(row.remaining.format())", bundle: .module) : String(localized: "Paid up", bundle: .module))
                                        .kText(KTextToken.caption, color: row.remaining.isPositive ? KColors.negative : KColors.positive)
                                }
                            }
                            Spacer()
                            if member.id == selected { Image(systemName: "checkmark").foregroundStyle(KColors.brand) }
                        }
                        .padding(.horizontal, KSpace.xl).padding(.vertical, KSpace.sm + 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, KSpace.xl)
                }
            }
        }
    }
}

/// What is being voided: a payment or a payout.
struct VoidTarget: Identifiable {
    let id: String
    let name: String
    let amount: Money
    let subtitle: String
    let isPayout: Bool
}

/// Void a payment or payout: entries are never edited or deleted, so a mistake
/// is voided with a reason and entered again.
struct VoidSheet: View {
    let target: VoidTarget
    let model: KametiDetailViewModel
    let onDone: () -> Void

    @State private var reason = ""
    @State private var isBusy = false
    @State private var failure: Failure?

    private var trimmed: String { reason.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            KCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(target.name).kText(KTextToken.bodyStrong)
                        Text(target.subtitle).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                    }
                    Spacer()
                    KMoneyText(target.amount, style: .title)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Why is this being voided?", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                TextField(String(localized: "e.g. Entered for the wrong member", bundle: .module), text: $reason)
                    .padding(.horizontal, KSpace.md)
                    .frame(minHeight: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.border))
            }
            Text("It stays in the history, struck through, and no longer counts.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSubtitle)
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
            }
            Button(action: submit) {
                ZStack {
                    Text(target.isPayout ? String(localized: "Void payout", bundle: .module) : String(localized: "Void payment", bundle: .module)).opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.negative)
            .controlSize(.large)
            .disabled(trimmed.isEmpty)
            .allowsHitTesting(!isBusy)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, KSpace.xl)
        .kDismissesKeyboard()
    }

    private func submit() {
        isBusy = true
        failure = nil
        Task {
            let result = target.isPayout
                ? await model.voidPayout(id: target.id, reason: trimmed)
                : await model.voidPayment(id: target.id, reason: trimmed)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}
