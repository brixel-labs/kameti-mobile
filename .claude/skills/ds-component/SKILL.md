---
name: ds-component
description: Create or change a reusable Kameti Design System (KDS) Flutter component, with tokens, all states, golden tests, a widget test and a Widgetbook use case. Use when a screen needs a UI element that isn't in docs/DESIGN_SYSTEM.md, or when changing an existing K* component.
argument-hint: "<KComponentName> <what it's for>"
---

# Add or change a KDS component

1. **Check first.** Search `docs/DESIGN_SYSTEM.md` and `lib/design_system/components/`. Prefer adding a variant or parameter to an existing component over making a new one. If it's needed in only one feature, it belongs in that feature's `presentation/widgets/` instead. Say which you chose and why.
2. **Design the API** and write it down before coding:
   - name `K<Name>`, file `lib/design_system/components/<group>/k_<name>.dart`;
   - required vs optional named parameters, callbacks (`VoidCallback?`, where null = disabled), and an enum for variants;
   - values in, callbacks out: no providers, no fetching, no business logic;
   - money as `Money`, never `double` or `String`.
3. **Implement:**
   - tokens only, through `context.k` (no literal colours, sizes or text styles);
   - `const` constructor, directional padding, `Semantics` for icon-only or custom controls, 44×44 touch targets;
   - every relevant state: default / pressed / focused / disabled / loading / error / empty / selected;
   - works at text scale 2.0 and in dark mode.
4. **Export** it from `lib/design_system/design_system.dart`.
5. **Test:**
   - golden: `test/design_system/<group>/k_<name>_golden_test.dart`, covering every variant and state, in light and dark, at text scale 1.0 and 2.0;
   - widget: `test/design_system/<group>/k_<name>_test.dart` for taps, disabled, loading and semantics labels.

   Run `flutter test test/design_system`. Update goldens only for intended changes (`--update-goldens`), and say so.
6. **Widgetbook:** add a use case per variant and state in `widgetbook/lib/components/<group>/`, with knobs for the main parameters.
7. **Docs:** add or update its row in `docs/DESIGN_SYSTEM.md` (API + notes) and a dartdoc comment with a short usage example.
8. **Changing an existing API** means updating every call site in the same change (`grep -rn "K<Name>(" lib`).
9. Ask the `design-system-guardian` agent to review the component before finishing.
