import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The create-kameti wizard, six steps (boards AC-1 to AC-6, FR-10 to FR-12).
/// Owner only: whoever creates the kameti owns it. The draft lives on the
/// server from step 1, so closing the wizard keeps it.
public struct CreateKametiView: View {
    @Bindable private var model: CreateWizardModel
    private let onStarted: (String) -> Void
    private let onClose: () -> Void

    public init(model: CreateWizardModel, onStarted: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.onStarted = onStarted
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            WizardProgress(step: model.step)
                .padding(.horizontal, KSpace.xl)
                .padding(.top, KSpace.xs)
            Group {
                switch model.step {
                case .basics: BasicsStep(model: model)
                case .dates: DatesStep(model: model)
                case .members: MembersStep(model: model)
                case .slots: SlotsStep(model: model)
                case .order: OrderStep(model: model)
                case .review: ReviewStep(model: model, onStart: onStarted, onSaveDraft: onClose)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(KColors.background)
        .kDismissesKeyboard()
        .navigationTitle(String(localized: "New kameti", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("Step \(model.step.rawValue + 1) of \(WizardStep.allCases.count)", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    .padding(.horizontal, KSpace.sm)
            }
            ToolbarItem(placement: .topBarLeading) {
                if model.isAtStart {
                    Button(String(localized: "Close", bundle: .module), systemImage: "xmark", action: onClose)
                } else {
                    Button(String(localized: "Back", bundle: .module), systemImage: "chevron.left") { model.back() }
                }
            }
        }
        .task { await model.loadOwner() }
        .alert(
            model.failure?.userMessage ?? "",
            isPresented: Binding(get: { model.failure != nil }, set: { if !$0 { model.clearFailure() } })
        ) {
            Button(String(localized: "OK", bundle: .module), role: .cancel) {}
        }
    }
}
