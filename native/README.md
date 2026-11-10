# Kameti native apps

Native rewrite of the Flutter app (`../lib`), iOS first. The Flutter app stays
in place as the reference until the native apps reach parity.

```
native/
  design-tokens/     tokens.json is the single source of truth; generate.py writes Swift
  ios/
    KametiKit/       Swift package with all app code (iOS 26, Swift 6)
    Kameti.xcodeproj the thin app target (created in Xcode 27.2, JSON .xcproj format)
```

## KametiKit layers (dependencies point inward)

| Target | Contains | Depends on |
|---|---|---|
| `KametiCore` | `Money`, `Failure`, Pakistan-time `KametiClock`, JSON rules | nothing |
| `KametiDomain` | backend row models, repository protocols (typed `throws(Failure)`) | Core |
| `KametiUI` | design tokens, components (SwiftUI) | Core |
| `KametiData` | supabase-swift implementations of the protocols | Domain, Core |
| features (to come) | screens + `@Observable` view models | Domain, UI (never Data) |

Only the app target links `KametiData` and wires it into the features, so every
view model is tested with fake repositories.

## Commands

```bash
# After editing design-tokens/tokens.json
python3 native/design-tokens/generate.py

# Unit tests (pick any available iPhone simulator id from `xcrun simctl list devices available`)
cd native/ios/KametiKit
xcodebuild test -scheme KametiKit-Package -destination 'id=<simulator-id>'
```

## Rules carried over from the Flutter app

- Money is `Money` (integer rupees), shown only through `KMoneyText`. Never `Double`.
- Balances and statuses come from the backend views; the app never recomputes them.
- Writes go through Postgres RPCs; reads use row-level-secured tables and views.
- All "which month is it" logic uses `KametiClock` (Asia/Karachi).
- Members never see write controls; the backend enforces it too.
