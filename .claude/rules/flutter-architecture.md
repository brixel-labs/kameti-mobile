---
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
  - "integration_test/**/*.dart"
  - "pubspec.yaml"
---

# Flutter architecture rules

## Structure (feature-first)

```
lib/
  main_dev.dart / main_staging.dart / main_prod.dart   # flavors → bootstrap()
  app/            # App widget, go_router config, route guards, bootstrap
  core/           # env, supabase client, errors (Failure), logging, Money, date (Asia/Karachi), utils
  design_system/  # KDS (see docs/DESIGN_SYSTEM.md)
  l10n/           # ARB files; generated AppLocalizations
  features/<feature>/
    data/         # DTOs (freezed + json), Supabase data sources, repository implementations
    domain/       # entities, repository interfaces, pure logic (ledger maths lives here)
    presentation/ # screens, controllers (Riverpod Notifiers), feature-only widgets
```

Features: `auth`, `home`, `kameti` (create/edit/lifecycle), `members`, `slots`, `payments`, `payouts`, `ledger`, `invites`, `reminders`, `notes`, `inbox`, `audit`, `export`, `settings`.

## Rules

1. **Dependencies point inward:** `presentation → domain ← data`. `domain` imports no Flutter, Supabase or Riverpod.
2. **State:** Riverpod with code generation (`@riverpod`). No `setState` for anything beyond local UI state (an expanded tile, for instance). No global singletons.
3. **Data access:** only repositories call Supabase. Every **write** goes through a Postgres RPC (`record_payment`, `record_payout`, …); never `insert`/`update` straight into tables from the app. Reads use RLS-protected views.
4. **Errors:** repositories return `Result<T, Failure>` (sealed), and never throw into the UI. Map Postgres/RLS errors to user-facing messages in l10n.
5. **Models:** `freezed`, immutable. Generated files (`*.g.dart`, `*.freezed.dart`) are committed, and kept up to date with `dart run build_runner build --delete-conflicting-outputs`.
6. **Navigation:** `go_router` with typed routes. Deep links `/kameti/join/:token` are handled in the router. Owner-only routes are guarded and also enforced by the backend.
7. **Role-based UI:** members never see write controls. Check `kameti.role == owner` in one place (`KametiAccess`), not ad hoc throughout the screens.
8. **Time:** all "which month is it / is it overdue" logic uses `KametiClock` (Asia/Karachi), never `DateTime.now()` directly, so tests can control time.
9. **Strings:** every user-facing string goes in `lib/l10n/app_en.arb`. No hard-coded UI text.
10. **Secrets:** only the Supabase **anon** key and URL in the app, through `--dart-define-from-file=env/<flavor>.json` (gitignored). Never the service-role key.
11. **Lints:** `very_good_analysis`, with zero warnings. `// ignore:` needs a reason comment.
12. **Tests:**
    - domain logic: unit tests, 100% of ledger code;
    - controllers: unit tests with mocked repositories (`mocktail`);
    - screens: widget tests for owner and member roles;
    - critical flows: `integration_test`.
13. **Performance:** long lists use `KSliverList` or a builder. No heavy work in `build()`. Use `select` on providers to avoid rebuilding everything.
