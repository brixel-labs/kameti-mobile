---
paths:
  - "ios/**/*.swift"
  - "ios/**/Package.swift"
---

# iOS architecture rules

## Structure

```
ios/
  Kameti/              thin app target: AppContainer wires KametiData into the features,
                       sign-in providers (Apple, Google), push, app icons, KametiConfig.json
  KametiKit/
    Sources/
      KametiCore/      Money, Failure, KametiClock (Asia/Karachi), small helpers
      KametiDomain/    backend row models, repository protocols, ProfileCache
      KametiUI/        tokens (generated), K* components, FailureMessage
      KametiData/      supabase-swift repositories, RPC params
      KametiNavigation/
      Feature*/        screens + @Observable view models (Auth, Home, CreateKameti,
                       KametiDetail, Invites, Shell)
      KametiTestSupport/ sample data and stub repositories (demo flavor, tests)
    Tests/             one test target per source target
```

## Rules

1. **Dependencies point inward:** `Feature* → Domain/UI → Core`; `Data → Domain → Core`. Features never import `KametiData`; only the app target wires it in.
2. **State:** `@Observable` view models on the main actor; views hold only local UI state (`@State`). No global singletons beyond the app's dependency container.
3. **Data access:** only repositories call Supabase. Every **write** goes through a Postgres RPC (`record_payment`, `record_payout`, …); never `insert`/`update` straight into tables. Reads use RLS-protected tables and views.
4. **Errors:** repositories use typed throws (`throws(Failure)`). Map Postgres/RLS errors to user-facing text in `FailureMessage`; never show raw error strings.
5. **Concurrency:** Swift 6 strict concurrency. Independent loads run together (`async let`, task groups); a failed extra never blocks the screen.
6. **Role-based UI:** members never see write controls. Check ownership in one place per screen, not ad hoc; the backend enforces it too.
7. **Time:** all "which month is it / is it overdue" logic uses `KametiClock` (Asia/Karachi), never `Date()` directly, so tests can control time.
8. **Strings:** user-facing text uses `String(localized:bundle: .module)` / `Text(_:bundle:)`, so it lands in the String Catalogs.
9. **Secrets:** only the Supabase URL and publishable key in the app, from `KametiConfig.json` (gitignored, written by `ios/scripts/use-env.sh`). Never the service-role key.
10. **Tests:** unit tests for logic and view models with stub repositories (`KametiTestSupport`); the ledger logic mirrors the backend views and is tested against the same fixtures.
11. **Performance:** long lists are lazy (`LazyVStack`/`List`); no heavy work in `body`.
