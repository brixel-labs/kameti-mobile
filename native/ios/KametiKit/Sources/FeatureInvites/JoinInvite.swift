import Foundation
import KametiCore
import KametiDomain
import KametiUI
import Observation
import SwiftUI

/// Loads an invite (from a link token, a 6-character code or an Inbox id)
/// and accepts or declines it.
@MainActor
@Observable
public final class JoinInviteViewModel {
    public enum State: Equatable, Sendable {
        case loading
        case loaded(InvitePreview)
        case failed(Failure)
        /// Accepted with another email: the owner has to approve first.
        case waiting(kametiName: String, ownerName: String)
        case declined(kametiName: String)
    }

    public private(set) var state = State.loading
    public private(set) var isBusy = false
    public private(set) var actionFailure: Failure?

    private let token: String?
    private let inviteId: String?
    private let invites: any InvitesRepository
    /// "Now" from the app clock, for "expires in" (fixed in the demo).
    public let now: Date

    public init(token: String?, inviteId: String?, dependencies: KametiDependencies) {
        self.token = token
        self.inviteId = inviteId
        self.invites = dependencies.invites
        self.now = dependencies.clock.now()
    }

    public func load() async {
        do throws(Failure) {
            state = .loaded(try await invites.previewInvite(token: token, inviteId: inviteId))
        } catch {
            state = .failed(error)
        }
    }

    /// Joins. Returns the kameti id when the member is in straight away.
    public func accept() async -> String? {
        guard case .loaded(let preview) = state else { return nil }
        isBusy = true
        actionFailure = nil
        defer { isBusy = false }
        do throws(Failure) {
            let member = try await invites.acceptInvite(token: token, inviteId: inviteId)
            if member.joinStatus == .joined { return member.kametiId }
            state = .waiting(kametiName: preview.kametiName, ownerName: preview.ownerName)
        } catch {
            actionFailure = error
        }
        return nil
    }

    public func decline() async {
        guard case .loaded(let preview) = state else { return }
        isBusy = true
        actionFailure = nil
        defer { isBusy = false }
        do throws(Failure) {
            _ = try await invites.declineInvite(token: token, inviteId: inviteId)
            state = .declined(kametiName: preview.kametiName)
        } catch {
            actionFailure = error
        }
    }
}

/// Accept invite (board AF-Join-Invite): who invited me, what I'd pay and
/// when my turn is, what members can see, then Join or Decline.
public struct JoinInviteView: View {
    let model: JoinInviteViewModel
    let onJoined: (String) -> Void
    let onClose: () -> Void

    @State private var confirmingDecline = false

    public init(model: JoinInviteViewModel, onJoined: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.onJoined = onJoined
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let failure):
                ContentUnavailableView {
                    Label(String(localized: "Can't open this invite", bundle: .module), systemImage: "envelope.badge")
                } description: {
                    Text(failure.userMessage)
                } actions: {
                    Button(String(localized: "Try again", bundle: .module)) { Task { await model.load() } }
                }
            case .loaded(let preview):
                loaded(preview)
            case .waiting(let kameti, let owner):
                outcome(
                    symbol: "hourglass", title: String(localized: "Waiting for approval", bundle: .module),
                    message: String(localized: "You signed in with a different email than the invite, so \(owner) needs to approve you. \(kameti) will show on Home once they do.", bundle: .module)
                )
            case .declined(let kameti):
                outcome(
                    symbol: "xmark.circle", title: String(localized: "Invite declined", bundle: .module),
                    message: String(localized: "You won't be added to \(kameti).", bundle: .module)
                )
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Invitation", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .task { if case .loading = model.state { await model.load() } }
    }

    private func loaded(_ preview: InvitePreview) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: KSpace.lg) {
                    VStack(spacing: KSpace.md) {
                        Text(InviteLogic.initials(preview.ownerName))
                            .kText(KTextStyle(size: 22, weight: .bold), color: KColors.onBrandSubtle)
                            .frame(width: 64, height: 64)
                            .background(KColors.brandSubtle, in: Circle())
                        Text("**\(preview.ownerName)** invited you to join", bundle: .module)
                            .kText(KTextToken.body, color: KColors.textSecondary)
                        Text(preview.kametiName).kText(KTextToken.titleLg).multilineTextAlignment(.center)
                    }
                    .padding(.top, KSpace.sm)

                    if !preview.isOpen {
                        Label(
                            preview.expired
                                ? String(localized: "This invite has expired. Ask \(preview.ownerName) to send a new one.", bundle: .module)
                                : String(localized: "This invite is no longer open.", bundle: .module),
                            systemImage: "exclamationmark.triangle"
                        )
                        .kText(KTextToken.bodySm, color: KColors.warning)
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(spacing: 0) {
                        row(String(localized: "Joining as", bundle: .module), preview.memberName)
                        if !preview.shares.isEmpty {
                            row(String(localized: "You pay each month", bundle: .module), InviteLogic.monthlyTotal(preview.shares).format())
                        }
                        if let turns = InviteLogic.turnsText(preview.shares, startMonth: preview.startMonth) {
                            row(String(localized: "Your turn", bundle: .module), turns)
                        }
                        if let months = preview.monthsN, !preview.shares.isEmpty {
                            row(String(localized: "You'll receive", bundle: .module), InviteLogic.payout(preview.shares, monthsN: months).format())
                        }
                        if let start = preview.startMonth, let months = preview.monthsN {
                            row(String(localized: "Runs", bundle: .module), InviteLogic.runsText(startMonth: start, monthsN: months))
                        }
                        row(String(localized: "Invite", bundle: .module), InviteLogic.expiryText(preview.expiresAt, now: model.now), last: true)
                    }
                    .padding(.horizontal, KSpace.lg)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(KColors.border))

                    VStack(alignment: .leading, spacing: KSpace.md) {
                        Label(String(localized: "You'll see your dues, the schedule and who has paid. Only \(preview.ownerName) can make changes.", bundle: .module), systemImage: "eye")
                        Label(String(localized: "Other members see your name, never your email.", bundle: .module), systemImage: "lock")
                        if !preview.emailMatches {
                            Label(String(localized: "You're signed in with a different email than the invite, so \(preview.ownerName) will approve you first.", bundle: .module), systemImage: "person.badge.clock")
                        }
                    }
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    .padding(KSpace.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(KColors.border))

                    if let failure = model.actionFailure {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                            .kText(KTextToken.bodySm, color: KColors.negative)
                    }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.bottom, KSpace.xl)
            }
            if preview.isOpen {
                SplitRow(spacing: KSpace.md) {
                    Button { confirmingDecline = true } label: {
                        Text("Decline", bundle: .module).kText(KTextToken.bodyStrong)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(KColors.border))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { if let id = await model.accept() { onJoined(id) } }
                    } label: {
                        ZStack {
                            Text("Join kameti", bundle: .module).opacity(model.isBusy ? 0 : 1)
                            if model.isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                        }
                        .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(KColors.brand)
                    .controlSize(.large)
                }
                .disabled(model.isBusy)
                .padding(.horizontal, KSpace.xl)
                .padding(.vertical, KSpace.md)
            }
        }
        .alert(String(localized: "Decline this invite?", bundle: .module), isPresented: $confirmingDecline) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Decline", bundle: .module), role: .destructive) { Task { await model.decline() } }
        } message: {
            Text("\(preview.ownerName) will see that you declined. They can invite you again later.", bundle: .module)
        }
    }

    private func row(_ title: String, _ value: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).kText(KTextToken.body, color: KColors.textSecondary)
                Spacer()
                Text(value).kText(KTextToken.bodyStrong).multilineTextAlignment(.trailing)
            }
            .padding(.vertical, KSpace.md)
            if !last { Divider() }
        }
    }

    private func outcome(symbol: String, title: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            Button(String(localized: "Back to Home", bundle: .module), action: onClose)
                .buttonStyle(.glassProminent)
                .tint(KColors.brand)
        }
    }
}
