import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// "Collect November" (board A v2 · Record many, option 3, tap to settle): tap a
/// person to mark what they owe, hold to edit the amount, then save them all
/// together with one date and method.
struct CollectMonthSheet: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let onDone: () -> Void

    @State private var session: CollectSession
    @State private var keys: [String: String]
    @State private var editing: String?
    @State private var receivedDate: Date
    @State private var method = PaymentMethod.cash
    @State private var reference = ""
    @State private var isBusy = false
    @State private var failure: Failure?

    init(data: KametiDetailData, model: KametiDetailViewModel, onDone: @escaping () -> Void) {
        self.data = data
        self.model = model
        self.onDone = onDone
        let session = CollectSession(data: data)
        _session = State(initialValue: session)
        // One key per member, made once, so a retry never records twice.
        _keys = State(initialValue: Dictionary(uniqueKeysWithValues: session.lines.map { ($0.memberId, model.idempotencyKey) }))
        _receivedDate = State(initialValue: RecordPaymentSheet.localDate(from: data.today))
    }

    private var byId: [String: Member] { Dictionary(data.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }) }
    private var receivedOn: Date { RecordPaymentSheet.utcDate(from: receivedDate) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    summary
                    // Only while someone is left to pay.
                    if !session.lines.isEmpty {
                        HStack {
                            Text(String(localized: "Tap to mark the full amount · hold to edit", bundle: .module).uppercased())
                                .kText(KTextToken.label, color: KColors.textSecondary)
                            Spacer(minLength: KSpace.sm)
                            KTonalButton(
                                session.allMarked ? String(localized: "Clear all", bundle: .module) : String(localized: "Mark all paid", bundle: .module),
                                style: .neutral
                            ) { withAnimation(.smooth(duration: 0.25)) { session.markAll() } }
                        }
                    }
                    if session.lines.isEmpty {
                        ContentUnavailableView(
                            String(localized: "Everyone has paid", bundle: .module), systemImage: "checkmark.circle",
                            description: Text("Nobody owes anything for this month.", bundle: .module)
                        )
                    }
                    ForEach(session.lines) { line in
                        if let member = byId[line.memberId] { row(member: member, line: line) }
                    }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.bottom, KSpace.lg)
            }
            footer
        }
        .kBottomSheet(
            isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } }),
            title: String(localized: "Amount", bundle: .module), detents: [.medium]
        ) {
            if let id = editing, let line = session.lines.first(where: { $0.memberId == id }), let member = byId[id] {
                EditAmountSheet(member: member, line: line, current: session.marked[id]) { amount in
                    session.set(id, to: amount)
                    editing = nil
                }
            }
        }
    }

    // MARK: Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            if let current = data.current {
                KPotProgress(collected: current.received, target: current.target, marked: session.total)
            }
            Text("Lighter bar = marked in this session, not saved yet", bundle: .module)
                .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
        }
    }

    // MARK: Rows

    private func row(member: Member, line: CollectSession.Line) -> some View {
        let state = session.state(of: line.memberId)
        let colorIndex = DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members)
        return HStack(spacing: KSpace.md) {
            KAvatar(name: member.name, colorIndex: colorIndex, size: .medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).kText(KTextToken.bodyStrong)
                statusLine(state, line: line)
            }
            Spacer(minLength: KSpace.sm)
            trailing(state, line: line)
        }
        .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
        .background(tint(state).bg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint(state).border))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { withAnimation(.smooth(duration: 0.2)) { session.toggle(line.memberId) } }
        .onLongPressGesture(minimumDuration: 0.35) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            editing = line.memberId
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private func statusLine(_ state: CollectSession.RowState, line: CollectSession.Line) -> some View {
        switch state {
        case .unmarked:
            Text("Owes \(line.remaining.format(symbol: false))", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
        case .settled(let amount):
            Text("+ \(amount.format()) · settled", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.positive)
        case .partial(let amount, let left):
            Text("+ \(amount.format()) · still owes \(left.format(symbol: false))", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.warning)
        }
    }

    @ViewBuilder private func trailing(_ state: CollectSession.RowState, line: CollectSession.Line) -> some View {
        switch state {
        case .unmarked:
            pill(String(localized: "Mark \(line.remaining.formatCompact())", bundle: .module), fg: KColors.brand, border: KColors.brand, fill: KColors.surface)
        case .settled:
            pill(String(localized: "Paid", bundle: .module), symbol: "checkmark", fg: KColors.textOnBrand, border: KColors.brand, fill: KColors.brand)
        case .partial:
            pill(String(localized: "Edit", bundle: .module), fg: KColors.warning, border: KColors.warning, fill: KColors.surface)
        }
    }

    private func pill(_ title: String, symbol: String? = nil, fg: Color, border: Color, fill: Color) -> some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol).font(.system(size: 12, weight: .bold)) }
            Text(title)
        }
        .kText(KTextStyle(size: 13, weight: .semibold), color: fg)
        .padding(.horizontal, 14).frame(height: 40)
        .background(fill, in: Capsule())
        .overlay(Capsule().stroke(border))
    }

    private func tint(_ state: CollectSession.RowState) -> (bg: Color, border: Color) {
        switch state {
        case .unmarked: (KColors.surface, KColors.border)
        case .settled: (KColors.positiveSubtle, KColors.positive.opacity(0.35))
        case .partial: (KColors.warningSubtle, KColors.warning.opacity(0.4))
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: KSpace.md) {
            DateMethodBar(
                prefix: String(localized: "Received", bundle: .module), date: $receivedDate, method: $method, reference: $reference,
                today: data.today, earliest: data.kameti.startMonth
            )
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
            }
if !KConnectivity.shared.isOnline {
                KOfflineActionBanner(String(localized: "Can't record payments offline. Connect and try again.", bundle: .module))
            }
            Button(action: save) {
                ZStack {
                    Text(saveTitle).opacity(isBusy ? 0 : 1)
                    if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                }
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(session.count == 0 || !KConnectivity.shared.isOnline)
            .allowsHitTesting(!isBusy)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.vertical, KSpace.md)
        .background(KColors.background)
    }

    private var saveTitle: String {
        session.count == 1
            ? String(localized: "Save 1 payment · \(session.total.format())", bundle: .module)
            : String(localized: "Save \(session.count) payments · \(session.total.format())", bundle: .module)
    }

    private func save() {
        let ref = reference.trimmingCharacters(in: .whitespaces)
        var items = session.items(keys: keys)
        if method == .bankTransfer, !ref.isEmpty { items = items.map { var item = $0; item.reference = ref; return item } }
        isBusy = true
        failure = nil
        Task {
            let result = await model.recordPayments(items: items, receivedOn: receivedOn, method: method)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}

/// Hold a person to set a different amount: their owed amount is one tap.
private struct EditAmountSheet: View {
    let member: Member
    let line: CollectSession.Line
    let current: Money?
    let onSet: (Money) -> Void
    @State private var digits: String

    init(member: Member, line: CollectSession.Line, current: Money?, onSet: @escaping (Money) -> Void) {
        self.member = member; self.line = line; self.current = current; self.onSet = onSet
        _digits = State(initialValue: String((current ?? line.remaining).rupees))
    }

    private var amount: Money { Money(parsing: digits) ?? .zero }

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            Text("How much did \(member.name) pay?", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            HStack(spacing: KSpace.sm) {
                Text("Rs").kText(KTextStyle(size: 20, weight: .semibold), color: KColors.textSecondary)
                KAmountInput(digits: $digits, prompt: "0").font(.system(size: 26, weight: .bold)).monospacedDigit()
            }
            .padding(.horizontal, KSpace.lg).frame(height: 60)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.brand, lineWidth: 2))
            KFlowLayout {
                KChip(String(localized: "Owes \(line.remaining.format(symbol: false))", bundle: .module), isOn: amount == line.remaining, style: .outlined) {
                    digits = String(line.remaining.rupees)
                }
                if line.remaining.rupees >= 2_000 {
                    KChip(String(localized: "Half \(Money(line.remaining.rupees / 2 / 1_000 * 1_000).format(symbol: false))", bundle: .module),
                          isOn: amount.rupees == line.remaining.rupees / 2 / 1_000 * 1_000, style: .outlined) {
                        digits = String(line.remaining.rupees / 2 / 1_000 * 1_000)
                    }
                }
            }
            Button { onSet(amount) } label: {
                Text(amount.isPositive ? String(localized: "Mark \(amount.format())", bundle: .module) : String(localized: "Clear", bundle: .module))
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, KSpace.xl)
        .kDismissesKeyboard()
    }
}
