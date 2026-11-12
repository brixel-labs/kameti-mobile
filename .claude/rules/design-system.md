---
paths:
  - "ios/**/*.swift"
---

# Design system rules (UI code)

The full catalogue is in `docs/DESIGN_SYSTEM.md`; the SwiftUI implementation is in `ios/KametiKit/Sources/KametiUI`. Read them before building or changing any screen.

1. **Build screens from KDS components** (`KCard`, `KButton`, `KPill`, `KAvatar`, `kBottomSheet`, `kConfirmSheet`, …). Before writing UI, check `KametiUI/Components` for an existing one.
2. **Never use raw styling in feature code:** no literal colours (`Color(red:…)`, `.blue`), font sizes or spacing numbers where a token exists. Use `KColors.*`, `KTextToken.*` with `.kText`, `KSpace.*` and `KRadius.*`.
3. **Sheets, not alerts:** confirmations and messages use `kConfirmSheet` / `kMessageSheet` / `kFailureSheet`, never `.alert`.
4. **Amounts:** always `Money` + `format()` / `KMoneyText` / the amount field. Never format money by hand and never use `Double`.
5. **Status** (paid, partial, overdue, etc.) always uses the chip components, which pair icon and text. Never show status by colour alone.
6. **Missing component?** If it's needed in two or more places, add it to KametiUI with the `ds-component` skill. If it's truly one-off, keep it in the feature, still built from tokens.
7. **Whole cards are tappable** when they lead somewhere, not just a chevron or link.
8. **Every screen handles** loading (skeletons), empty, error (with retry) and offline (banner).
9. **Destructive or money-changing actions** (void, payout with shortfall, removing a member) go through `kConfirmSheet`. Buttons that write show a spinner and ignore repeat taps.
10. Tokens come from `design-tokens/tokens.json`; regenerate with `python3 design-tokens/generate.py`, never edit `Tokens.generated.swift` by hand.
