import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// "Know when it matters" (board AN-4): asked once, after the first kameti.
struct PushPermissionSheet: View {
    let onAllow: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            Image(systemName: "bell")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(KColors.brand)
                .frame(width: 56, height: 56)
                .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: 16))
            Text("Know when it matters", bundle: .module).kText(KTextToken.titleLg)
            Text("Kameti tells you when a payment is due, when someone pays or joins, and when it's your turn. Nothing else.", bundle: .module)
                .kText(KTextToken.body, color: KColors.textSecondary)
            VStack(spacing: KSpace.sm) {
                example("checkmark", String(localized: "Office kameti", bundle: .module), String(localized: "Hira paid Rs 50,000 for November", bundle: .module))
                example("person.fill", String(localized: "Office kameti", bundle: .module), String(localized: "Muhammad Hassan wants to join. Tap to review.", bundle: .module))
                example("clock", String(localized: "Family kameti", bundle: .module), String(localized: "Rs 25,000 is due by the 10th", bundle: .module))
            }
            Spacer(minLength: 0)
            Button(action: onAllow) {
                Text("Turn on notifications", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textOnBrand).frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            Button(action: onLater) {
                Text("Not now", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.bottom, KSpace.lg)
    }

    private func example(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: KSpace.md) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(KColors.textOnBrand)
                .frame(width: 30, height: 30)
                .background(KColors.brand, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).kText(KTextStyle(size: 13, weight: .semibold))
                Text(body).kText(KTextToken.bodySm)
            }
            Spacer(minLength: 0)
        }
        .padding(KSpace.md)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// Profile → Notifications (board AN-5): is this phone allowed, and what to push.
struct NotificationSettingsView: View {
    let userId: String
    let dependencies: KametiDependencies

    @State private var preferences: NotificationPreferences?
    @State private var failure: Failure?
    @Environment(\.openURL) private var openURL
    private var push: PushCenter { .shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.md) {
                statusBanner
                Text("Send me".uppercased()).kText(KTextToken.label, color: KColors.textSecondary).padding(.top, KSpace.sm)
                VStack(spacing: 0) {
                    toggle(String(localized: "Payment reminders", bundle: .module),
                           String(localized: "Before your dues are due, on the days each kameti sets", bundle: .module), \.notifyReminders)
                    toggle(String(localized: "Payments and payouts", bundle: .module),
                           String(localized: "A payment recorded for you, your payout next month, paid out", bundle: .module), \.notifyPayments)
                    toggle(String(localized: "Invites and joining", bundle: .module),
                           String(localized: "Invitations to you; for kametis you run: join requests, joined, declined", bundle: .module), \.notifyInvites)
                    toggle(String(localized: "Changes to a kameti", bundle: .module),
                           String(localized: "Payout order changed, a share transferred", bundle: .module), \.notifyChanges, last: true)
                }
                .padding(.horizontal, KSpace.lg)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 16))
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
                }
                Text("Everything also shows in your Inbox, even when it's off here. The owner's \"remind everyone\" message always comes through unless you turn notifications off for Kameti in iPhone Settings.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    .padding(.horizontal, KSpace.xxs)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.vertical, KSpace.md)
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Notifications", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await push.refreshStatus()
            do throws(Failure) { preferences = try await dependencies.notifications.preferences(userId: userId) } catch { failure = error }
        }
    }

    @ViewBuilder private var statusBanner: some View {
        if push.isAllowed {
            Label(String(localized: "Notifications are on for this iPhone", bundle: .module), systemImage: "checkmark")
                .kText(KTextToken.bodyStrong, color: KColors.brand)
                .padding(KSpace.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: 14))
        } else {
            VStack(alignment: .leading, spacing: KSpace.sm) {
                Label(String(localized: "Notifications are off for this iPhone", bundle: .module), systemImage: "bell.slash")
                    .kText(KTextToken.bodyStrong, color: KColors.warning)
                Button {
                    if push.status == .notDetermined {
                        Task { await push.requestPermission() }
                    } else if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text(push.status == .notDetermined ? String(localized: "Turn on", bundle: .module) : String(localized: "Open iPhone Settings", bundle: .module))
                        .kText(KTextToken.bodyStrong, color: KColors.brand)
                }
                .buttonStyle(.plain)
            }
            .padding(KSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func toggle(_ title: String, _ detail: String, _ key: WritableKeyPath<NotificationPreferences, Bool>, last: Bool = false) -> some View {
        let binding = Binding<Bool>(
            get: { preferences?[keyPath: key] ?? true },
            set: { value in
                guard var updated = preferences else { return }
                updated[keyPath: key] = value
                let previous = preferences
                preferences = updated
                Task {
                    do throws(Failure) {
                        try await dependencies.notifications.updatePreferences(userId: userId, updated)
                        failure = nil
                    } catch {
                        preferences = previous
                        failure = error
                    }
                }
            }
        )
        return VStack(spacing: 0) {
            Toggle(isOn: binding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).kText(KTextToken.bodyStrong)
                    Text(detail).kText(KTextToken.bodySm, color: KColors.textSecondary)
                }
            }
            .toggleStyle(KToggleStyle())
            .disabled(preferences == nil)
            .padding(.vertical, KSpace.md)
            if !last { Divider() }
        }
    }
}
