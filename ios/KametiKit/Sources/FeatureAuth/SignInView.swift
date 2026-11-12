import KametiCore
import KametiUI
import SwiftUI

/// Sign-in screen (board AF-Sign-In): Continue with Apple and Google, plus two
/// dev buttons in a dev build.
public struct SignInView: View {
    @Bindable private var model: SignInViewModel

    public init(model: SignInViewModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            Spacer()
            RoundedRectangle(cornerRadius: KRadius.xl * 0.8)
                .fill(KColors.brand)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(KColors.textOnBrand)
                        .accessibilityHidden(true)
                }
            Text("Run your kameti.\nTrack every turn.", bundle: .module)
                .kText(KTextToken.displayLg)
                .fixedSize(horizontal: false, vertical: true)
            Text("Record who paid, see whose turn is next, and remind members, all in one place.", bundle: .module)
                .kText(KTextToken.body, color: KColors.textSecondary)
            Spacer()
            if let failure = model.failure { FailureBanner(failure: failure) }
            buttons
        }
        .padding(.horizontal, KSpace.xl)
        .padding(.bottom, KSpace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(KColors.background)
    }

    @ViewBuilder private var buttons: some View {
        VStack(spacing: KSpace.sm) {
            Button {
                Task { await model.signIn(with: .apple) }
            } label: {
                SignInLabel(busy: model.busyProvider == .apple, color: KColors.textOnBrand) {
                    Image(systemName: "apple.logo")
                    Text("Continue with Apple", bundle: .module)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)

            Button {
                Task { await model.signIn(with: .google) }
            } label: {
                SignInLabel(busy: model.busyProvider == .google) {
                    KGoogleLogo()
                    Text("Continue with Google", bundle: .module)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.surface)

            if model.showsDevSignIn {
                Divider().padding(.vertical, KSpace.xs)
                ForEach(DevAccount.allCases, id: \.self) { account in
                    Button {
                        Task { await model.signIn(as: account) }
                    } label: {
                        SignInLabel(busy: model.busyDevAccount == account) {
                            Text(account == .owner ? "Dev: sign in as owner" : "Dev: sign in as member", bundle: .module)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .controlSize(.large)
        .allowsHitTesting(!model.isBusy)
    }
}

private struct SignInLabel<Content: View>: View {
    let busy: Bool
    var color: Color = .primary
    @ViewBuilder let content: Content

    var body: some View {
        // The content stays in the layout (hidden) while busy, so the button
        // keeps its height and the spinner is drawn on top of it.
        HStack(spacing: KSpace.sm) { content }
            .opacity(busy ? 0 : 1)
            .overlay { if busy { ProgressView().controlSize(.small).tint(color) } }
        .kText(KTextToken.bodyStrong, color: color)
        .frame(maxWidth: .infinity)
    }
}

/// The reason a sign-in failed, in plain words. Raw causes never reach the screen.
private struct FailureBanner: View {
    let failure: Failure

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                .kText(KTextToken.bodySm, color: KColors.negative)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.negativeSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
    }
}
