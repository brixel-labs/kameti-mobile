---
paths:
  - "android/**/*.kt"
  - "android/**/*.kts"
---

# Android architecture rules

The Android app is a port of the iOS app, kept file-for-file close to it: when a screen or rule changes on one platform, change the other the same way. `ios-architecture.md` describes the same layers in Swift.

## Structure

```
android/
  app/                 thin app module: AppContainer wires :data into the features,
                       sign-in providers, push, icons, assets/KametiConfig.json
  core/                Money, Failure, KametiClock (Asia/Karachi), DateOnly, KametiJson   (pure Kotlin)
  domain/              backend row models, repository interfaces, KametiDependencies      (pure Kotlin)
  navigation/          Route, AppRouter, DeepLink                                         (pure Kotlin)
  testsupport/         sample data and stub repositories (demo flavor, tests)             (pure Kotlin)
  ui/                  tokens (generated), K* components, FailureMessage                  (Compose)
  data/                supabase-kt repositories, RPC params
  feature/             auth, home, kametidetail, createkameti, invites, shell:
                       screens + view models
  build-logic/         the `kameti.*` convention plugins every module applies
  scripts/             use-env.sh, import-strings.py
```

Package names follow the module: `:feature:home` is `com.brixel.kameti.feature.home`.

## Rules

1. **Dependencies point inward:** `:feature:* → :domain / :ui → :core`; `:data → :domain → :core`. Features never depend on `:data`; only `:app` wires it in.
2. **Build files:** a module applies one convention plugin (`kameti.jvm.library`, `kameti.android.library`, `kameti.android.compose`, `kameti.android.feature`, `kameti.android.application`) and lists only its own dependencies. Versions live in `gradle/libs.versions.toml`.
3. **State:** one `ViewModel` per screen exposing a `StateFlow` of an immutable UI state; composables hold only local UI state (`remember`). No global singletons beyond the app's dependency container.
4. **Data access:** only repositories call Supabase. Every **write** goes through a Postgres RPC (`record_payment`, `record_payout`, …); never `insert`/`update` straight into tables. Reads use RLS-protected tables and views.
5. **Errors:** repositories throw only `Failure`. Map Postgres/RLS errors to user-facing text in `FailureMessage`; never show raw error strings. Never swallow `CancellationException`.
6. **Concurrency:** coroutines. Independent loads run together (`async`); a failed extra never blocks the screen (`attempt { }`).
7. **Role-based UI:** members never see write controls. Check ownership in one place per screen, not ad hoc; the backend enforces it too.
8. **Time:** all "which month is it / is it overdue" logic uses `KametiClock` (Asia/Karachi), never `Instant.now()` / `LocalDate.now()` directly, so tests can control time. A calendar day or month is a `LocalDate`; a moment is an `Instant`.
9. **Money:** `Money` (whole rupees, `Long`). Never `Double` or `Float`; show amounts only through `Money.format()` / `KMoneyText`.
10. **Strings:** user-facing text comes from `strings.xml`, which `android/scripts/import-strings.py` writes from the iOS String Catalogs. Add or change wording in the catalog, then run the script; find a name with `--find "text"`. Wording only Android needs ("Back", the Android developer hint) goes in the module's hand-written `strings_android.xml`, named `<prefix>_android_*`.
11. **Tokens:** `ui/.../generated/Tokens.generated.kt` is written by `python3 design-tokens/generate.py`; never edit it by hand. Feature code uses `KColors`, `KSpace`, `KRadius`, `KTextToken` and `K*` components, never raw colours, sizes or Material components directly.
12. **Secrets:** only the Supabase URL and publishable key in the app, from `assets/KametiConfig.json` (gitignored, written by `android/scripts/use-env.sh`). Never the service-role key, a keystore or `google-services.json` in git.
13. **Tests:** each iOS test file has a Kotlin twin with the same cases and fixtures. Pure Kotlin modules keep their tests on the JVM.
14. **Navigation:** screens push `Route`s on `AppRouter` and never open each other directly; `:feature:shell` maps a route to its screen (`RouteDestination`) and gives each stack entry its own saved state and `ViewModelStore` (`RouteEntries.kt`), so a screen's view model is created with `viewModel { … }` and is cleared when the screen is popped.
15. **Sign-in:** Google only, and native (Credential Manager in `:app`, the ID token goes to Supabase in `:data`). Android has no Sign in with Apple (the owner's decision, 2026-11-14); iOS keeps both. `:data` exposes only `KametiBackend`, `ProviderCredentialSource` and `SignInNonce`; the repositories are `internal`.
16. **Performance:** long lists are lazy (`LazyColumn`); no heavy work in composition.
