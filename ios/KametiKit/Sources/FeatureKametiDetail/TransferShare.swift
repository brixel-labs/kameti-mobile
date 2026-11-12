import Foundation
import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The rules behind moving a share (FR-33), mirroring the backend's `transfer_share`.
enum TransferLogic {
    /// A member's shares that can still move: running kameti, not already ended.
    static func movableShares(of member: Member, in data: KametiDetailData) -> [Share] {
        guard data.kameti.status == .active else { return [] }
        return data.shares
            .filter { $0.memberId == member.id && $0.effectiveToMonth == nil && firstMonth(for: $0, in: data) != nil }
            .sorted { payoutMonth(of: $0, in: data) < payoutMonth(of: $1, in: data) }
    }

    /// The earliest month it can move from: this month (or month 1 before the
    /// start), never before the share began. `nil` once every month has passed.
    static func firstMonth(for share: Share, in data: KametiDetailData) -> Int? {
        let current = data.current?.monthIndex ?? (data.today < data.kameti.startMonth ? 1 : data.kameti.monthsN + 1)
        let first = max(current, share.effectiveFromMonth)
        return first <= data.kameti.monthsN ? first : nil
    }

    static func payoutMonth(of share: Share, in data: KametiDetailData) -> Int {
        data.slots.first { $0.id == share.slotId }?.payoutMonthIndex ?? 0
    }

    /// Members who can take the share: not its holder, not already in that
    /// slot, and under the slot limit.
    static func candidates(for share: Share, in data: KametiDetailData) -> [Member] {
        data.members.filter { member in
            member.id != share.memberId
                && !data.shares.contains { $0.slotId == share.slotId && $0.memberId == member.id && $0.effectiveToMonth == nil }
                && DetailLogic.slotCount(of: member, shares: data.shares) < data.kameti.maxSlotsPerMember
        }
    }

    /// How much the current holder has paid so far (all their payments).
    static func paidSoFar(by member: Member, in data: KametiDetailData) -> Money {
        data.balances.first { $0.memberId == member.id }?.totalPaid ?? .zero
    }
}

/// Transfer a member's share (board AT-1): pick the share, who takes it over
/// and from which month, with an optional settlement note and a live summary.
struct TransferShareSheet: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let member: Member
    let onDone: () -> Void

    @State private var shareId: String
    @State private var targetId: String?
    @State private var addingNew = false
    @State private var newName = ""
    @State private var fromMonth: Date
    @State private var note = ""
    @State private var isBusy = false
    @State private var failure: Failure?

    init(data: KametiDetailData, model: KametiDetailViewModel, member: Member, onDone: @escaping () -> Void) {
        self.data = data; self.model = model; self.member = member; self.onDone = onDone
        let first = TransferLogic.movableShares(of: member, in: data).first
        _shareId = State(initialValue: first?.id ?? "")
        let month = first.flatMap { TransferLogic.firstMonth(for: $0, in: data) } ?? 1
        _fromMonth = State(initialValue: DetailLogic.monthStart(of: data.kameti, monthIndex: month))
    }

    private var shares: [Share] { TransferLogic.movableShares(of: member, in: data) }
    private var share: Share? { shares.first { $0.id == shareId } }
    private var firstName: String { MemberLogic.firstName(member.name) }
    private var fromIndex: Int { DetailLogic.monthIndex(of: fromMonth, kameti: data.kameti) ?? 1 }
    private var target: Member? { targetId.flatMap { id in data.members.first { $0.id == id } } }
    private var targetName: String? {
        addingNew ? (MemberLogic.isValidName(newName) ? MemberLogic.trimmed(newName) : nil) : target?.name
    }
    private var allowedMonths: [Date] {
        guard let share, let first = TransferLogic.firstMonth(for: share, in: data) else { return [] }
        return (first...data.kameti.monthsN).map { DetailLogic.monthStart(of: data.kameti, monthIndex: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                if let share {
                    shareSection(share)
                    targetSection(share)
                    KMonthField(String(localized: "From", bundle: .module), selection: $fromMonth, months: allowedMonths)
                    noteField
                    summary(share)
                    if let failure {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
                    }
                    transferButton
                } else {
                    Text("\(firstName) has no share that can move.", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
    }

    // MARK: Sections

    private func label(_ text: String) -> some View {
        Text(text).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
    }

    private func slotTitle(_ share: Share) -> String {
        let month = TransferLogic.payoutMonth(of: share, in: data)
        return String(localized: "Slot \(month) · paid out \(DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: month)))", bundle: .module)
    }

    @ViewBuilder private func shareSection(_ share: Share) -> some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Share", bundle: .module))
            if shares.count > 1 {
                KFlowLayout {
                    ForEach(shares) { item in
                        KChip(String(localized: "Slot \(TransferLogic.payoutMonth(of: item, in: data)) · \(item.monthlyAmount.format())", bundle: .module),
                              isOn: item.id == shareId, style: .outlined) { select(item) }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(slotTitle(share)).kText(KTextToken.bodyStrong)
                Text(String(localized: "\(share.monthlyAmount.format()) a month", bundle: .module)).kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KSpace.md)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.brand))
        }
    }

    private func targetSection(_ share: Share) -> some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Goes to", bundle: .module))
            KFlowLayout {
                ForEach(TransferLogic.candidates(for: share, in: data)) { person in
                    KChip(person.name, isOn: !addingNew && targetId == person.id, style: .outlined) {
                        addingNew = false; targetId = person.id
                    }
                }
                KChip(String(localized: "Someone new", bundle: .module), symbol: "plus", isOn: addingNew, style: .outlined) {
                    addingNew = true; targetId = nil
                }
            }
            if addingNew {
                TextField(String(localized: "Their name", bundle: .module), text: $newName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, KSpace.md)
                    .frame(minHeight: 48)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label(String(localized: "Settlement note (optional)", bundle: .module))
            TextField(String(localized: "e.g. Sara pays Ali back Rs 2,50,000 in cash", bundle: .module), text: $note, axis: .vertical)
                .lineLimit(2...4)
                .padding(KSpace.md)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
        }
    }

    private func summary(_ share: Share) -> some View {
        let who = targetName.map(MemberLogic.firstName) ?? String(localized: "the new holder", bundle: .module)
        let payout = TransferLogic.payoutMonth(of: share, in: data)
        let payoutName = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: payout)).split(separator: " ").first.map(String.init) ?? ""
        let fromTitle = DetailLogic.monthTitle(fromMonth)
        let receives = payout >= fromIndex
            ? String(localized: "From \(fromTitle), \(who) pays \(share.monthlyAmount.format()) a month and receives the \(payoutName) payout.", bundle: .module)
            : String(localized: "From \(fromTitle), \(who) pays \(share.monthlyAmount.format()) a month. The \(payoutName) payout already went to \(firstName).", bundle: .module)
        let keeps = fromIndex > share.effectiveFromMonth
            ? String(localized: "\(firstName) keeps the \(TransferLogic.paidSoFar(by: member, in: data).format()) paid so far and pays nothing for this share after \(DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: fromIndex - 1))).", bundle: .module)
            : String(localized: "Nothing has been due on this share yet, so it simply changes hands.", bundle: .module)
        return VStack(alignment: .leading, spacing: KSpace.sm) {
            Text("What changes", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.brand)
            Text(receives).kText(KTextToken.body)
            Text(keeps).kText(KTextToken.bodySm, color: KColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KSpace.md + 2)
        .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: 14))
    }

    private var transferButton: some View {
        Button(action: transfer) {
            ZStack {
                Text(targetName.map { String(localized: "Transfer to \(MemberLogic.firstName($0))", bundle: .module) }
                     ?? String(localized: "Transfer share", bundle: .module))
                    .opacity(isBusy ? 0 : 1)
                if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
            }
            .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(KColors.brand)
        .controlSize(.large)
        .disabled(targetName == nil)
        .allowsHitTesting(!isBusy)
    }

    // MARK: Actions

    private func select(_ item: Share) {
        shareId = item.id
        targetId = nil
        if let first = TransferLogic.firstMonth(for: item, in: data), fromIndex < first {
            fromMonth = DetailLogic.monthStart(of: data.kameti, monthIndex: first)
        }
    }

    private func transfer() {
        guard let share else { return }
        let to: KametiDetailViewModel.TransferTarget
        if addingNew {
            guard MemberLogic.isValidName(newName) else { return }
            to = .newPerson(name: MemberLogic.trimmed(newName))
        } else {
            guard let targetId else { return }
            to = .member(targetId)
        }
        kDismissKeyboard()
        isBusy = true
        failure = nil
        Task {
            let result = await model.transferShare(shareId: share.id, to: to, fromMonth: fromIndex, note: note)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}
