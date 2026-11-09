---
paths:
  - "lib/**/*.dart"
  - "widgetbook/**/*.dart"
  - "test/**/*.dart"
---

# Design system rules (UI code)

The full catalogue is in `docs/DESIGN_SYSTEM.md`. Read it before building or changing any screen.

1. **Build screens only from KDS components** (`K*` widgets from `package:kameti/design_system/design_system.dart`). Before writing UI, check the catalogue for an existing component.
2. **Never use raw styling in feature code:**
   - no `Color(...)`, `Colors.*`, `TextStyle(...)`, `Theme.of(context).textTheme…`;
   - no numeric `EdgeInsets`, `SizedBox(height: 13)` or `BorderRadius.circular(8)`;
   - use `context.k.colors.*`, `context.k.text.*`, `context.k.space.*`, `context.k.radius.*`, or `KGap.md` for spacing.
3. **Never use raw Material widgets in feature code** when a KDS one exists: `ElevatedButton`/`TextButton` → `KButton`, `TextFormField` → `KTextField`/`KAmountField`, `SnackBar` → `context.showToast`, `AlertDialog` → `KConfirmDialog`, `showModalBottomSheet` → `showKSheet`, `Scaffold` → `KScaffold`, `AppBar` → `KAppBar`, `Chip` → `KStatusChip`.
4. **Amounts:** always `Money` + `KMoneyText` / `KAmountField`. Never format money by hand and never use `double`.
5. **Status** (paid, partial, overdue, etc.) always uses the chip components, which pair icon and text. Never show status by colour alone.
6. **Missing component?** Don't hand-roll it in the feature. If it's needed in two or more places, add it to KDS with the `ds-component` skill. If it's truly one-off, put it in `features/<x>/presentation/widgets/`, still built from KDS pieces and tokens.
7. **Directional layout:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`, never `left`/`right` (Urdu RTL in v1.1).
8. **Every screen handles** loading (`KSkeleton`), empty (`KEmptyState`), error (`KErrorState` with retry) and offline (`KInfoBanner`).
9. **Destructive or money-changing actions** (void, unlink, reorder after start, payout with shortfall, removing a member) go through `KConfirmDialog`. Buttons that write show `isLoading` and ignore repeat taps.
10. Inside `lib/design_system/` itself, components may use Flutter primitives, but only with token values.
