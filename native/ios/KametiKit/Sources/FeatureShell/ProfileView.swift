import KametiDomain
import KametiCore
import KametiUI
import SwiftUI

/// Profile and settings (board AF · Profile, icon list option): who you are,
/// notification and appearance settings, account rows, help, and sign out.
public struct ProfileView: View {
    @Bindable private var model: ProfileViewModel
    @State private var confirmingSignOut = false
    @State private var choosingAppearance = false
    @AppStorage(KAppearance.storageKey) private var appearance = KAppearance.system.rawValue
    // Stored on the phone for now; push notifications arrive with the
    // notifications backend, which reads these later.
    @AppStorage("kameti.notify.reminders") private var remindersOn = true
    @AppStorage("kameti.notify.updates") private var updatesOn = true

    public init(model: ProfileViewModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: KSpace.lg) {
                if let profile = model.profile {
                    profileCard(profile)
                } else if let failure = model.failure {
                    ContentUnavailableView {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button(String(localized: "Try again", bundle: .module)) { Task { await model.load() } }
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(.vertical, KSpace.xl)
                }
                group {
                    toggleRow(String(localized: "Payment reminders", bundle: .module), symbol: "bell", tint: .amber, isOn: $remindersOn)
                    toggleRow(String(localized: "Updates", bundle: .module), symbol: "megaphone", tint: .blue, isOn: $updatesOn)
                    row(String(localized: "Appearance", bundle: .module), symbol: "moon", tint: .purple,
                        value: (KAppearance(rawValue: appearance) ?? .system).title, isLast: true) { choosingAppearance = true }
                }
                group {
                    row(String(localized: "My people", bundle: .module), symbol: "person.2", tint: .green, value: "\(model.peopleCount)")
                    row(String(localized: "Sign-in methods", bundle: .module), symbol: "key", tint: .grey)
                    row(String(localized: "Past kametis", bundle: .module), symbol: "archivebox", tint: .blue, value: "\(model.pastCount)", isLast: true)
                }
                group {
                    row(String(localized: "Support", bundle: .module), symbol: "questionmark.circle", tint: .green)
                    row(String(localized: "Privacy policy", bundle: .module), symbol: "shield", tint: .grey, isLast: true)
                }
                group {
                    row(String(localized: "Sign out", bundle: .module), symbol: "rectangle.portrait.and.arrow.right", tint: .grey, showsChevron: false) {
                        confirmingSignOut = true
                    }
                    row(String(localized: "Delete account", bundle: .module), symbol: "trash", tint: .red, color: KColors.negative,
                        showsChevron: false, isLast: true)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Profile", bundle: .module))
        .alert(String(localized: "Sign out of Kameti?", bundle: .module), isPresented: $confirmingSignOut) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Sign out", bundle: .module), role: .destructive) { Task { await model.signOut() } }
        } message: {
            Text("You'll need to sign in again to see your kametis.", bundle: .module)
        }
        .kBottomSheet(isPresented: $choosingAppearance, title: String(localized: "Appearance", bundle: .module), detents: [.height(300)]) {
            VStack(spacing: 0) {
                ForEach(KAppearance.allCases, id: \.self) { option in
                    Button {
                        appearance = option.rawValue
                        choosingAppearance = false
                    } label: {
                        HStack {
                            Text(option.title).kText(KTextToken.body)
                            Spacer()
                            if option.rawValue == appearance { Image(systemName: "checkmark").foregroundStyle(KColors.brand) }
                        }
                        .padding(.horizontal, KSpace.xl).padding(.vertical, KSpace.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, KSpace.xl)
                }
                Spacer(minLength: 0)
            }
        }
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    // MARK: Pieces

    private func profileCard(_ profile: Profile) -> some View {
        HStack(spacing: KSpace.lg) {
            KAvatar(name: profile.displayName, colorIndex: 0, size: .large)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName).kText(KTextToken.titleLg)
                Text("\(model.runningCount) kametis run · \(model.memberCount) joined", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
            Spacer(minLength: KSpace.sm)
            Image(systemName: "chevron.right").foregroundStyle(KColors.textTertiary)
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
    }

    private func group<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, KSpace.lg)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
    }

    private enum Tint {
        case amber, blue, purple, green, grey, red

        var colors: (fg: Color, bg: Color) {
            switch self {
            case .amber: (KColors.warning, KColors.warningSubtle)
            case .blue: (KColors.info, KColors.infoSubtle)
            case .purple: (KColors.info, KColors.infoSubtle)
            case .green: (KColors.onBrandSubtle, KColors.brandSubtle)
            case .grey: (KColors.textSecondary, KColors.surfaceSunken)
            case .red: (KColors.negative, KColors.negativeSubtle)
            }
        }
    }

    private func icon(_ symbol: String, _ tint: Tint) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(tint.colors.fg)
            .frame(width: 30, height: 30)
            .background(tint.colors.bg, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
    }

    private func row(
        _ title: String, symbol: String, tint: Tint, value: String? = nil, color: Color = KColors.textPrimary,
        showsChevron: Bool = true, isLast: Bool = false, action: (() -> Void)? = nil
    ) -> some View {
        Button { action?() } label: {
            VStack(spacing: 0) {
                HStack(spacing: KSpace.md) {
                    icon(symbol, tint)
                    Text(title).kText(KTextToken.body, color: color)
                    Spacer(minLength: KSpace.sm)
                    if let value { Text(value).kText(KTextToken.bodySm, color: KColors.textSecondary) }
                    if showsChevron { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(KColors.textTertiary) }
                }
                .frame(minHeight: 52)
                if !isLast { Divider().padding(.leading, 42) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, symbol: String, tint: Tint, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: isOn) {
                HStack(spacing: KSpace.md) {
                    icon(symbol, tint)
                    Text(title).kText(KTextToken.body)
                }
            }
            .toggleStyle(KToggleStyle())
            .frame(minHeight: 52)
            Divider().padding(.leading, 42)
        }
    }
}
