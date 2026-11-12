---
name: ds-component
description: Create or change a reusable Kameti Design System (KDS) SwiftUI component in KametiUI, with tokens, all states, light and dark. Use when a screen needs a UI element that isn't in KametiUI, or when changing an existing K* component.
argument-hint: "<KComponentName> <what it's for>"
---

# Add or change a KDS component

1. **Check first.** Search `docs/DESIGN_SYSTEM.md` and `ios/KametiKit/Sources/KametiUI/Components/`. Prefer adding a parameter to an existing component over a new one.
2. **Place it** in `KametiUI/Components/` (a new file `K<Name>.swift`, or the matching group file such as `KInputs.swift` or `KLayout.swift`). Name `K<Name>` for views, `k<Name>` for modifiers. `public`, with a doc comment and a short usage example.
3. **Tokens only:** `KColors`, `KSpace`, `KRadius`, `KTextToken` + `.kText`. If a value is missing, add it to `design-tokens/tokens.json` and run `python3 design-tokens/generate.py`.
4. **API:** values in, closures out; no repositories or view models inside. Cover every state: enabled, disabled, loading, selected, error.
5. **Accessibility:** labels on icon-only controls, 44×44 touch targets, status never by colour alone, Dynamic Type doesn't clip.
6. **Check** it in light and dark on a simulator, and add a unit test in `Tests/KametiUITests` where there's logic.
7. **Docs:** add or update its row in `docs/DESIGN_SYSTEM.md`.
