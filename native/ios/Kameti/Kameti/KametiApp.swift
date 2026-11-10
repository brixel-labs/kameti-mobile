import KametiCore
import KametiUI
import SwiftUI

@main
struct KametiApp: App {
    var body: some Scene {
        WindowGroup {
            // Placeholder until the real shell lands: proves KametiKit is linked.
            VStack(alignment: .leading, spacing: KSpace.lg) {
                Text("Kameti").kText(KTextToken.titleLg)
                KPotProgress(collected: Money(2_350_000), target: Money(5_000_000))
                KBalancePill(balance: Money(-125_000))
            }
            .padding(KSpace.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(KColors.background)
        }
    }
}
