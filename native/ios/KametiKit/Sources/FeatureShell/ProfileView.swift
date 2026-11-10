import KametiCore
import KametiUI
import SwiftUI

/// Profile tab (board AF-Profile): who you are, how many kametis, sign out.
public struct ProfileView: View {
    @Bindable private var model: ProfileViewModel
    @State private var confirmingSignOut = false

    public init(model: ProfileViewModel) {
        self.model = model
    }

    public var body: some View {
        List {
            if let profile = model.profile {
                Section {
                    VStack(spacing: KSpace.md) {
                        KAvatar(name: profile.displayName, colorIndex: 0, size: .large)
                        Text(profile.displayName).kText(KTextToken.titleLg)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                Section {
                    LabeledContent(String(localized: "Kametis I run", bundle: .module)) {
                        Text("\(model.runningCount)").monospacedDigit()
                    }
                    LabeledContent(String(localized: "Kametis I'm in", bundle: .module)) {
                        Text("\(model.memberCount)").monospacedDigit()
                    }
                }
            } else if let failure = model.failure {
                ContentUnavailableView {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Try again") { Task { await model.load() } }
                }
            } else {
                ProgressView().frame(maxWidth: .infinity).listRowBackground(Color.clear)
            }
            Section(String(localized: "Account", bundle: .module)) {
                Button(role: .destructive) {
                    confirmingSignOut = true
                } label: {
                    Label(String(localized: "Sign out", bundle: .module), systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(KColors.background)
        .navigationTitle(String(localized: "Profile", bundle: .module))
        .confirmationDialog(
            String(localized: "Sign out of Kameti?", bundle: .module),
            isPresented: $confirmingSignOut, titleVisibility: .visible
        ) {
            Button(String(localized: "Sign out", bundle: .module), role: .destructive) {
                Task { await model.signOut() }
            }
        } message: {
            Text("You'll need to sign in again to see your kametis.", bundle: .module)
        }
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}
