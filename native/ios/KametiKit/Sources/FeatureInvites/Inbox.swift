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

/// Inbox for this slice: invitations to me and join requests I need to
/// answer. The activity feed (payments, reminders) comes with the activity log.
@MainActor
@Observable
public final class InboxViewModel {
    public private(set) var invitations: [MyInvitation] = []
    public private(set) var requests: [JoinRequest] = []
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

    public var isEmpty: Bool { invitations.isEmpty && requests.isEmpty }

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
            failure = nil
        } catch {
            failure = error
        }
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

/// Inbox (board AF-Inbox): join requests first, then invitations.
public struct InboxView: View {
    let model: InboxViewModel
    let onOpenInvitation: (String) -> Void

    @State private var reviewing: JoinRequest?
    @State private var declining: MyInvitation?
    @State private var declineFailure: Failure?

    public init(model: InboxViewModel, onOpenInvitation: @escaping (String) -> Void) {
        self.model = model
        self.onOpenInvitation = onOpenInvitation
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
                    description: Text("Invitations and join requests will show here.", bundle: .module)
                )
            } else {
                List {
                    if !model.requests.isEmpty {
                        Section(String(localized: "Waiting for you", bundle: .module)) {
                            ForEach(model.requests) { request in
                                Button { reviewing = request } label: {
                                    item(
                                        symbol: "person.badge.clock", tint: KColors.info, background: KColors.infoSubtle,
                                        title: String(localized: "\(request.member.name) wants to join", bundle: .module),
                                        detail: String(localized: "\(request.kametiName) · signed in with a different email. Tap to review.", bundle: .module)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if !model.invitations.isEmpty {
                        Section(String(localized: "Invitations", bundle: .module)) {
                            ForEach(model.invitations) { invitation in
                                Button { onOpenInvitation(invitation.inviteId) } label: {
                                    item(
                                        symbol: "envelope", tint: KColors.brand, background: KColors.brandSubtle,
                                        title: String(localized: "\(invitation.ownerName) invited you", bundle: .module),
                                        detail: "\(invitation.kametiName) · \(InviteLogic.expiryText(invitation.expiresAt, now: model.now))"
                                    )
                                }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button(String(localized: "Decline", bundle: .module), role: .destructive) { declining = invitation }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Inbox", bundle: .module))
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
                Task { declineFailure = await model.decline(invitation) }
            }
        } message: { invitation in
            Text("\(invitation.ownerName) will see that you declined \(invitation.kametiName).", bundle: .module)
        }
        .alert(
            String(localized: "Couldn't decline", bundle: .module),
            isPresented: Binding(get: { declineFailure != nil }, set: { if !$0 { declineFailure = nil } }), presenting: declineFailure
        ) { _ in
            Button(String(localized: "OK", bundle: .module)) {}
        } message: { failure in
            Text(failure.userMessage)
        }
    }

    private func item(symbol: String, tint: Color, background: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: KSpace.md) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(background, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).kText(KTextToken.bodyStrong)
                Text(detail).kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(KColors.textTertiary)
                .padding(.top, KSpace.sm)
        }
        .padding(.vertical, KSpace.xs)
        .contentShape(Rectangle())
    }
}
