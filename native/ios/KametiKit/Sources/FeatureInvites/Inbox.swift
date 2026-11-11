import Foundation
import KametiCore
import KametiDomain
import KametiUI
import Observation
import SwiftUI

/// Someone who accepted an invite to a kameti I run, waiting for approval.
public struct JoinRequest: Identifiable, Equatable, Sendable {
    public let member: Member
    public let kametiName: String
    public let invitedEmail: String?
    public let acceptedEmail: String?
    public var id: String { member.id }
}

/// Inbox (board AN-1): what needs me (invitations to me, join requests for
/// kametis I run) and Updates, the notifications feed (FR-86).
@MainActor
@Observable
public final class InboxViewModel {
    public private(set) var invitations: [MyInvitation] = []
    public private(set) var requests: [JoinRequest] = []
    public private(set) var updates: [AppNotification] = []
    public private(set) var failure: Failure?
    public private(set) var hasLoaded = false
    public let now: Date

    private let userId: String
    private let dependencies: KametiDependencies

    public init(userId: String, dependencies: KametiDependencies) {
        self.userId = userId
        self.dependencies = dependencies
        self.now = dependencies.clock.now()
    }

    public var isEmpty: Bool { invitations.isEmpty && requests.isEmpty && updates.isEmpty }
    public var needsYou: Int { invitations.count + requests.count }
    public var unreadUpdates: Int { updates.filter(\.isUnread).count }
    /// The tab badge and app icon badge.
    public var badgeCount: Int { needsYou + unreadUpdates }

    public func load() async {
        defer { hasLoaded = true }
        do throws(Failure) {
            invitations = try await dependencies.invites.myInvitations()
            var found: [JoinRequest] = []
            let mine = try await dependencies.kametis.listKametis()
                .filter { $0.isOwned(by: userId) && ($0.status == .active || $0.status == .draft) }
            for kameti in mine {
                let waiting = (try? await dependencies.kametis.members(kametiId: kameti.id))?.filter { $0.joinStatus == .pendingApproval } ?? []
                guard !waiting.isEmpty else { continue }
                let invites = (try? await dependencies.invites.invites(kametiId: kameti.id)) ?? []
                for member in waiting {
                    let accepted = invites.first { $0.memberId == member.id && $0.status == .accepted }
                    found.append(JoinRequest(
                        member: member, kametiName: kameti.name, invitedEmail: accepted?.email, acceptedEmail: accepted?.acceptedEmail
                    ))
                }
            }
            requests = found
            // Updates are extra: if they fail, the rest still shows.
            updates = (try? await dependencies.notifications.notifications(limit: 60)) ?? updates
            failure = nil
        } catch {
            failure = error
        }
    }

    /// Opening an update marks it read (optimistically; the server follows).
    public func markRead(_ update: AppNotification) {
        guard update.isUnread, let index = updates.firstIndex(of: update) else { return }
        updates[index] = update.markedRead(at: now)
        Task { try? await dependencies.notifications.markRead(ids: [update.id]) }
    }

    public func markAllRead() {
        guard unreadUpdates > 0 else { return }
        updates = updates.map { $0.isUnread ? $0.markedRead(at: now) : $0 }
        Task { try? await dependencies.notifications.markRead(ids: nil) }
    }

    public func decline(_ invitation: MyInvitation) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.invites.declineInvite(token: nil, inviteId: invitation.inviteId)
        } catch {
            return error
        }
        await load()
        return nil
    }

    public func approve(_ request: JoinRequest) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.invites.approveJoin(memberId: request.member.id) } catch { return error }
        await load()
        return nil
    }

    public func reject(_ request: JoinRequest) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.invites.declineJoin(memberId: request.member.id) } catch { return error }
        await load()
        return nil
    }
}

/// Inbox (board AN-1): "Needs you" cards with their actions on top, then
/// the Updates feed with unread dots.
public struct InboxView: View {
    let model: InboxViewModel
    let onOpenInvitation: (String) -> Void
    let onOpenKameti: (String) -> Void

    @State private var reviewing: JoinRequest?
    @State private var declining: MyInvitation?
    @State private var rejecting: JoinRequest?
    @State private var actionFailure: Failure?

    public init(model: InboxViewModel, onOpenInvitation: @escaping (String) -> Void, onOpenKameti: @escaping (String) -> Void = { _ in }) {
        self.model = model
        self.onOpenInvitation = onOpenInvitation
        self.onOpenKameti = onOpenKameti
    }

    public var body: some View {
        Group {
            if !model.hasLoaded {
                ScrollView { KSkeletonRows(rows: 3).padding(.horizontal, KSpace.xl).padding(.top, KSpace.md) }
            } else if let failure = model.failure, model.isEmpty {
                ScrollView {
                    KMessageCard(
                        String(localized: "Couldn't load your inbox", bundle: .module), message: failure.helpMessage,
                        actionTitle: String(localized: "Try again", bundle: .module)
                    ) { Task { await model.load() } }
                    .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            } else if model.isEmpty {
                ContentUnavailableView(
                    String(localized: "You're all caught up", bundle: .module), systemImage: "tray",
                    description: Text("Invitations, join requests and updates about your kametis show here.", bundle: .module)
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: KSpace.sm) {
                        if model.needsYou > 0 {
                            sectionTitle(String(localized: "Needs you · \(model.needsYou)", bundle: .module))
                            ForEach(model.requests) { requestCard($0) }
                            ForEach(model.invitations) { invitationCard($0) }
                        }
                        if !model.updates.isEmpty {
                            sectionTitle(String(localized: "Updates", bundle: .module)).padding(.top, model.needsYou > 0 ? KSpace.md : 0)
                            VStack(spacing: 0) {
                                ForEach(Array(model.updates.enumerated()), id: \.element.id) { index, update in
                                    updateRow(update, last: index == model.updates.count - 1)
                                }
                            }
                            .padding(.horizontal, KSpace.lg)
                            .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, KSpace.xl)
                    .padding(.bottom, KSpace.xl)
                }
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Inbox", bundle: .module))
        .toolbar {
            if model.unreadUpdates > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Mark all read", bundle: .module)) { model.markAllRead() }
                        .tint(KColors.brand)
                }
            }
        }
        .task { await model.load() }
        .refreshable { await model.load() }
        .kBottomSheet(
            isPresented: Binding(get: { reviewing != nil }, set: { if !$0 { reviewing = nil } }),
            title: String(localized: "Join request", bundle: .module), detents: [.large]
        ) {
            if let request = reviewing {
                ApproveJoinSheet(
                    memberName: request.member.name, invitedEmail: request.invitedEmail, acceptedEmail: request.acceptedEmail,
                    approve: { await model.approve(request) }, reject: { await model.reject(request) }, onDone: { reviewing = nil }
                )
            }
        }
        .alert(
            String(localized: "Decline this invite?", bundle: .module),
            isPresented: Binding(get: { declining != nil }, set: { if !$0 { declining = nil } }), presenting: declining
        ) { invitation in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Decline", bundle: .module), role: .destructive) {
                Task { actionFailure = await model.decline(invitation) }
            }
        } message: { invitation in
            Text("\(invitation.ownerName) will see that you declined \(invitation.kametiName).", bundle: .module)
        }
        .alert(
            String(localized: "Decline \(rejecting?.member.name ?? "")'s request?", bundle: .module),
            isPresented: Binding(get: { rejecting != nil }, set: { if !$0 { rejecting = nil } }), presenting: rejecting
        ) { request in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Decline", bundle: .module), role: .destructive) {
                Task { actionFailure = await model.reject(request) }
            }
        } message: { request in
            Text("They won't be linked to \(request.kametiName). You can invite them again later.", bundle: .module)
        }
        .alert(
            String(localized: "Something went wrong", bundle: .module),
            isPresented: Binding(get: { actionFailure != nil }, set: { if !$0 { actionFailure = nil } }), presenting: actionFailure
        ) { _ in
            Button(String(localized: "OK", bundle: .module)) {}
        } message: { failure in
            Text(failure.userMessage)
        }
    }

    // MARK: Pieces

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
            .padding(.top, KSpace.md).padding(.bottom, KSpace.xxs).padding(.horizontal, KSpace.xxs)
    }

    private func icon(_ symbol: String, tint: Color, background: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 38, height: 38)
            .background(background, in: Circle())
    }

    private func card(
        symbol: String, tint: Color, background: Color, title: String, detail: String,
        primary: String, onPrimary: @escaping () -> Void, onDecline: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            HStack(alignment: .top, spacing: KSpace.md) {
                icon(symbol, tint: tint, background: background)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).kText(KTextToken.bodyStrong)
                    Text(detail).kText(KTextToken.bodySm, color: KColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            SplitRow(spacing: KSpace.sm, firstShare: 0.5) {
                Button(action: onDecline) {
                    Text("Decline", bundle: .module).kText(KTextToken.bodyStrong)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                Button(action: onPrimary) {
                    Text(primary).kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(KColors.brand, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(KColors.border))
    }

    private func requestCard(_ request: JoinRequest) -> some View {
        card(
            symbol: "person.badge.clock", tint: KColors.info, background: KColors.infoSubtle,
            title: String(localized: "\(request.member.name) wants to join", bundle: .module),
            detail: String(localized: "\(request.kametiName) · signed in with a different email", bundle: .module),
            primary: String(localized: "Review", bundle: .module),
            onPrimary: { reviewing = request }, onDecline: { rejecting = request }
        )
    }

    private func invitationCard(_ invitation: MyInvitation) -> some View {
        card(
            symbol: "envelope", tint: KColors.brand, background: KColors.brandSubtle,
            title: String(localized: "\(invitation.ownerName) invited you", bundle: .module),
            detail: "\(invitation.kametiName) · \(InviteLogic.expiryText(invitation.expiresAt, now: model.now))",
            primary: String(localized: "View and join", bundle: .module),
            onPrimary: { onOpenInvitation(invitation.inviteId) }, onDecline: { declining = invitation }
        )
    }

    private func updateRow(_ update: AppNotification, last: Bool) -> some View {
        let style = InboxLogic.style(for: update.kind)
        return Button {
            model.markRead(update)
            if update.opensKameti, let kametiId = update.kametiId { onOpenKameti(kametiId) }
        } label: {
            HStack(alignment: .top, spacing: KSpace.md) {
                icon(style.symbol, tint: style.tint, background: style.background)
                VStack(alignment: .leading, spacing: 3) {
                    Text(update.title).kText(KTextToken.bodyStrong)
                    Text(update.body).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    Text(InboxLogic.ago(update.createdAt, now: Date())).kText(KTextToken.caption, color: KColors.textSecondary)
                }
                Spacer(minLength: 0)
                if update.isUnread {
                    Circle().fill(KColors.brand).frame(width: 8, height: 8).padding(.top, 6)
                        .accessibilityLabel(Text("Unread", bundle: .module))
                }
            }
            .padding(.vertical, KSpace.md)
            .overlay(alignment: .bottom) { if !last { Divider() } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// How each kind of update looks, and "2 h ago".
enum InboxLogic {
    struct Style {
        let symbol: String
        let tint: Color
        let background: Color
    }

    static func style(for kind: String) -> Style {
        switch kind {
        case "payment", "approved": Style(symbol: "checkmark", tint: KColors.positive, background: KColors.positiveSubtle)
        case "payout", "payout_soon": Style(symbol: "arrow.up.right", tint: KColors.warning, background: KColors.warningSubtle)
        case "payment_void", "declined", "join_declined": Style(symbol: "xmark", tint: KColors.negative, background: KColors.negativeSubtle)
        case "joined": Style(symbol: "person.fill", tint: KColors.brand, background: KColors.brandSubtle)
        case "join_request": Style(symbol: "person.badge.clock", tint: KColors.info, background: KColors.infoSubtle)
        case "invite": Style(symbol: "envelope", tint: KColors.brand, background: KColors.brandSubtle)
        case "reminder": Style(symbol: "bell", tint: KColors.warning, background: KColors.warningSubtle)
        default: Style(symbol: "arrow.left.arrow.right", tint: KColors.textSecondary, background: KColors.surfaceSunken)
        }
    }

    static func ago(_ date: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return String(localized: "Just now", bundle: .module)
        case ..<3600: return String(localized: "\(Int(seconds / 60)) min ago", bundle: .module)
        case ..<86_400: return String(localized: "\(Int(seconds / 3600)) h ago", bundle: .module)
        case ..<172_800: return String(localized: "Yesterday", bundle: .module)
        default: return date.formatted(.dateTime.day().month(.abbreviated))
        }
    }
}
