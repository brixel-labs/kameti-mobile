# Kameti Design System (KDS)

Every screen in the app is built from these components. A screen never styles raw Flutter widgets itself.

> **Status:** direction **A "Ledger"** chosen (2026-11-09), with a dark mode. Token values below come from the design board: https://claude.ai/artifact/CU8Y4xmfhCPFHoMyavyf6e (row A).

## 1. Where things live

```
lib/design_system/
  tokens/
    k_colors.dart        # semantic colour tokens (light + dark)
    k_typography.dart    # text styles
    k_spacing.dart       # spacing scale
    k_radius.dart        # corner radii
    k_elevation.dart     # shadows
    k_motion.dart        # durations, curves
    k_icons.dart         # icon set mapping
  theme/
    k_theme.dart         # ThemeExtension<KTheme> holding all tokens; light() / dark()
    k_theme_x.dart       # BuildContext extension: context.k.colors.surface …
  components/
    buttons/  inputs/  money/  display/  feedback/  navigation/  layout/  kameti/
  design_system.dart     # single barrel export
widgetbook/              # Widgetbook app: every component, every state, light/dark
test/design_system/      # golden + widget tests
```

Feature code imports **only** `package:kameti/design_system/design_system.dart`.

## 2. Tokens

All tokens are **semantic**: named for their job, not their look. Write `colors.positive`, never `green500`.

| Group | Tokens |
|---|---|
| **Colour: surfaces** | `background`, `surface`, `surfaceRaised`, `surfaceSunken`, `overlay`, `border`, `divider` |
| **Colour: content** | `textPrimary`, `textSecondary`, `textTertiary`, `textOnBrand`, `textDisabled`, `icon` |
| **Colour: brand** | `brand`, `brandPressed`, `brandSubtle`, `accent` |
| **Colour: status** | `positive` (paid), `positiveSubtle`, `warning` (partial / due soon), `warningSubtle`, `negative` (unpaid / overdue / shortfall), `negativeSubtle`, `info` (advance / credit), `infoSubtle`, `neutral` (upcoming) |
| **Colour: member palette** | `avatars` (8 × `KAvatarColors{background, foreground}`), read with `colors.avatar(index)` which wraps the index |
| **Typography** | `displayLg` (big money figures), `display`, `titleLg`, `title`, `titleSm`, `body`, `bodyStrong`, `bodySm`, `label`, `caption`, `mono` (amounts in tables, tabular figures) |
| **Spacing** | `xxs 2`, `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `xxxl 48` |
| **Radius** | `sm 6`, `md 10`, `lg 16`, `xl 24`, `pill 999` |
| **Elevation** | `none`, `low`, `mid`, `high` |
| **Motion** | `fast 120ms`, `base 200ms`, `slow 320ms`; curves `standard`, `emphasized` |
| **Layout** | screen gutter = `lg`; min touch target 44×44; max content width 600 (tablets later) |

Every colour pair used for text must pass **WCAG AA** in both light and dark.

### 2.1 Token values (direction A, "Ledger")

| Token | Light | Dark |
|---|---|---|
| `background` | `#F6F7F5` | `#0E1513` |
| `surface` | `#FFFFFF` | `#16201D` |
| `surfaceSunken` | `#EEF0ED` | `#1E2A26` |
| `border` | `#E4E7E3` (inputs `#D5DAD6`) | `#26332E` |
| `divider` | `#EEF0ED` | `#1E2A26` |
| `overlay` | `rgba(18,32,27,0.45)` | `rgba(0,0,0,0.6)` |
| `textPrimary` | `#12201B` | `#E8EFEC` |
| `textSecondary` | `#4E5D57` | `#A3B1AC` |
| `textTertiary` | `#8A958F` | `#7D8B86` |
| `brand` | `#0E6B52` | `#3FBF94` |
| `textOnBrand` | `#FFFFFF` | `#06231A` |
| `brandSubtle` (bg / text) | `#E3F1EC` / `#0E6B52` | `#173A2F` / `#7FDDB8` |
| `positive` (bg / text) | `#E2F4EA` / `#13804F` | `#163527` / `#4CC98A` |
| `warning` (bg / text) | `#FFF1DC` / `#8A4B00` | `#3A2A12` / `#F2B25C` |
| `negative` (bg / text) | `#FDE8E6` / `#B42318` | `#3D1D1B` / `#FF8A80` |
| `info` (bg / text) | `#E5EEFB` / `#1D5FBF` | `#1A2A45` / `#7FB0FF` |
| "Your turn" highlight (bg / border / text) | `#FFF1DC` / `#C27A00` / `#6B3A00` | `#3A2A12` / `#8A6420` / `#FFE2B8` |

- **Font:** Inter (400/500/600/700) via `google_fonts` or bundled. All amounts use **tabular figures** (`FontFeature.tabularFigures()`).
- **Type sizes:** `displayLg` 34/700 · `display` 30/700 · `titleLg` 24/700 · `title` 17/600 · `body` 15/400 · `bodyStrong` 15/600 · `bodySm` 13/400 · `label` 13/600 uppercase +0.6 tracking · `caption` 12/400.
- **Shapes:** cards radius 16, inputs and buttons 12–14, chips pill. Cards are flat with a 1 px border; no shadows, except the FAB and a dragged row.
- **Primary button:** 52–54 high, radius 14. **Inputs:** 44–48 high; the focused or main amount field has a 2 px brand border.

## 3. Components

Naming: `K` + PascalCase. One public widget per file, `snake_case` file name (`k_button.dart`).

### 3.1 Buttons
| Component | Variants / API | Notes |
|---|---|---|
| `KButton` | `.primary`, `.secondary`, `.tertiary`, `.destructive`; `label`, `onPressed`, `icon?`, `leading?` (a custom ~20 px widget such as a brand logo, shown instead of `icon`), `isLoading`, `size: sm/md/lg`, `expand` | `onPressed: null` = disabled. Loading shows a spinner and ignores taps (prevents double payments) |
| `KIconButton` | `icon`, `semanticLabel` (required), `onPressed`, `variant: plain/brand/outlined`, `size` (glyph) | Always a 44×44 hit area |
| `KFab` | `icon`, `label?`, `onPressed` | Owner's main action, e.g. "Record payment" |
| `KTextLink` | `label`, `onTap` | Inline link |

### 3.2 Inputs
| Component | API | Notes |
|---|---|---|
| `KTextField` | `label`, `hint?`, `helper?`, `error?`, `controller`, `validator`, `keyboardType`, `prefix?`, `suffix?`, `maxLength?` | Base for all inputs |
| `KAmountField` | `value: Money?`, `onChanged(Money?)`, `label?`, `helper?`, `error?`, `step` (Rs 1,000), `min?`, `max?`, `suggestions: [KAmountSuggestion(amount, label?)]`, `emphasized` (56 px, 2 px brand border; default true) | `Rs` prefix, lakh grouping as you type (`KLakhInputFormatter`), digits only. Built-in step/min/max errors; `KAmountField.issueFor(...)` gives the same check for submit buttons. Chips are `KAmountChip` |
| `KSearchField` | `onChanged`, `hint?`, `debounce` (250 ms) | Clear button (labelled) fires `onChanged('')` at once |
| `KMonthPicker` | `value`, `firstMonth`, `lastMonth`, `onChanged`, `label?`, `hint?`, `error?` | Opens a `showKSheet` with year switcher + 3×4 month grid. Months in/out are `DateTime.utc(y, m)` like `KametiClock.currentMonth()` |
| `KDatePicker` | `value`, `lastDate` (**required**), `onChanged`, `firstDate?` (lastDate − 10 y), `label?`, `hint?`, `error?` | Payment dates can't be in the future (FR-46). `lastDate` is required because KDS never reads the device clock: pass `clock.now()`. A value after `lastDate` shows a built-in error |
| `KDropdown<T>` / `KSelectSheet<T>` | `items`, `value`, `itemLabel`, `onChanged` | Opens a bottom sheet on mobile |
| `KMemberPicker` | `members`, `selected`, `multi: bool`, `onChanged` | Search, avatars, "select all not invited" |
| `KSegmentedControl<T>` | `segments: [KSegment(value, label, icon?)]`, `value`, `onChanged?` | e.g. Cash / Bank / Other. `onChanged: null` disables |
| `KSwitchTile`, `KCheckboxTile`, `KRadioTile<T>` | `title`, `subtitle?`, `value`, `onChanged?` | Whole row toggles; merged semantics. `KRadioTile` not built yet |
| `KWizardProgress` | `step` (1-based), `total` (6), `showLabel` | Create-kameti wizard bars; announced "Step 4 of 6". (Replaces `KStepper`) |

### 3.3 Money (core to this app)
| Component | API | Notes |
|---|---|---|
| `KMoneyText` | `amount: Money`, `style: display/title/body/mono`, `compact: bool`, `signed: bool`, `tone: auto/neutral/positive/negative` | **The only way to show an amount.** Formats `Rs 24,00,000`; compact `24 L` / `2.4 Cr`. `signed` shows `+` / `−` for credit and dues |
| `KBalancePill` | `balance: Money` | Positive balance = "Owes Rs X" (negative tone); zero = "Settled"; negative balance = "Credit Rs X" (info tone). Built-in l10n text + icon |
| `KPotProgress` | `collected`, `target`, `marked` (Money.zero), `showLabels`, `caption?` | "Rs 23,50,000 of 50,00,000 · 47%"; `marked` (tap-to-settle, unsaved) is added to the headline and drawn as a lighter segment; "Over by Rs X" on overpayment. `percentOf(amount, target)` helper |
| `KShareSplitEditor` | `slotAmount`, `sharers: [KSharer(id, name, colorIndex, amount?, subtitle?)]`, `onChanged(index, Money?)`, `maxSharers` (4), `step`, `onAddSharer?` + `addSharerLabel`, `onRemoveSharer?` | Amount chips per sharer from `suggestedAmounts(slot)` (round amounts ≤ half the slot, e.g. 25K/50K/1L/1.25L) + Custom (focuses the inline box); "Give the rest: Rs X" on the last sharer; "Assigned X of C" bar, which turns negative with "Over by" when the total passes C. Chips that would overshoot are disabled. `issueFor(slot, amounts)` → `KShareSplitIssue?` for the Next button. **No fraction presets** |
| `KSettleRow` | `name`, `colorIndex`, `imageUrl?`, `owed: Money`, `marked: Money?`, `onMarkFull`, `onEdit`, `onUndo` | Tap-to-settle row (FR-43): "Mark 1.25 L" → "✓ Paid" (undo); a partial shows "still owes X" in warning tone with Edit; long-press = edit. Button moves under the text from text scale 1.5 |
| `KAmountSummaryRow` | `label`, `amount`, `emphasis` | Label/value rows in summaries and receipts |

### 3.4 Display
| Component | API | Notes |
|---|---|---|
| `KCard` | `child`, `onTap?`, `padding`, `variant: flat/raised/outlined` | |
| `KListTile` | `leading?`, `title`, `subtitle?`, `trailing?`, `onTap?`, `onLongPress?`, `showDivider` | Base row. From text scale 1.5 the trailing widget moves under the title (never truncated) |
| `KAvatar` | `name`, `colorIndex`, `size: sm 30/md 36/lg 48`, `imageUrl?`, `ringColor?`, `semanticLabel?` | Initials fallback (`initialsOf`); decorative unless `semanticLabel` is given |
| `KAvatarStack` | `members: [KAvatarData(name, colorIndex, imageUrl?)]`, `max` (3), `size`, `ringColor?` | Shared slot recipients, "+2" overflow; reads names to screen readers |
| `KStatusChip` | `KPaymentStatus` {paid, partial, unpaid, overdue, advance, upcoming} | Icon + text, **never colour alone** |
| `KMonthStatusChip` | `status: KMonthStatus` {upcoming, collecting, collected, paidOut, paidOutShort}, `label?` | Built-in l10n label + icon |
| `KInviteStatusChip` | `status: KJoinStatus` {notInvited, invited, pendingApproval, joined, declined, expired, bounced}, `label?` | Built-in label; pass e.g. "Invited 2d ago" |
| `KBadge` | `count` or `dot` | Inbox, approvals |
| `KSectionHeader` | `title`, `actionLabel?`, `onAction?` | Upper-cased label, header semantics |
| `KDivider` | — | |
| `KInfoBanner` | `tone: KBannerTone` {info, warning, negative, positive, **neutral**}, `message`, `icon?`, `actionLabel?`, `onAction?` | `neutral` is the offline notice. Icon per tone |
| `KKeyValueList` | `items: [KKeyValue(label, value: String? \| amount: Money?, emphasis)]`, `title?` | Detail and summary cards; amounts via `KMoneyText`; wraps at large text |
| `KPill` | `label`, `foreground`, `background`, `icon?` | Shape behind the chips; KDS-internal building block |

### 3.5 Kameti-specific (built only from the components above)
| Component | Shows |
|---|---|
| `KKametiCard` | Home card: name, role badge (Owner/Member), "Month 2 of 20", this month's recipient(s), your due status, pot progress |
| `KSlotTile` | Payout month, recipient avatar stack, shares, month status; drag handle when reorderable; lock icon when paid out |
| `KMemberRow` | Avatar, name/nickname, monthly due, balance pill, invite status (owner) |
| `KPaymentRow` | Date, amount, method, "paid by" note, void state (struck through + "Voided") |
| `KPayoutRow` | Recipient, amount, date, expected vs actual |
| `KMonthGridCell` / `KMonthGrid` | Spreadsheet-like members × months grid, status per cell, horizontal scroll, pinned first column |
| `KScheduleGrid` / `KMonthTile` | Payout schedule as a 4-column grid of month tiles (chosen design): paid out = filled brand, now = outlined info, your turn = amber highlight; tapping a tile shows that month's recipients below. API: `KScheduleGrid(months: [KScheduleMonth(month, recipients, state: KMonthTileState{upcoming, now, paidOut}, isYourTurn)], selectedIndex?, onSelect?, showLegend, columns: 4)`; `KMonthTile(month, recipients, state, isYourTurn, selected, onTap?)` |
| `KNoteTile` | Note text, author, time, Private/Shared tag |
| `KAuditTile` | Who did what, when, before → after |
| `KReminderCard` | Next reminder date, "Remind unpaid members" with sent-today state |

### 3.6 Feedback
| Component | API | Notes |
|---|---|---|
| `KEmptyState` | `title`, `message?`, `icon?`, `actionLabel?`, `onAction?` | Every list has one |
| `KErrorState` | `message`, `onRetry?`, `title?`, `retryLabel?` ("Try again"), `isRetrying` | |
| `KSkeleton` / `KSkeletonList` | `KSkeleton(width?, height, radius)`, `.circle(size)`; `KSkeletonList(rows: 3)` | Loading: no full-screen spinners for content. Static (no shimmer) so `pumpAndSettle` never hangs; the list is announced once as "Loading" |
| `KLoadingOverlay` | `isLoading` | Blocking writes only |
| `KToast` (`context.showToast`) | `message`, `tone: KToastTone{neutral, positive, negative}`, `actionLabel?`, `onAction?`, `duration` | Snackbar replacement, e.g. "Payment recorded · Undo"; replaces any toast already showing |
| `KConfirmDialog` / `showKConfirm` | `title`, `message`, `confirmLabel`, `cancelLabel?`, `destructive` → `Future<bool>` | Required before void, unlink, reorder after start, payout with shortfall. Dismiss = false |
| `showKSheet<T>` | `builder`, `title?`, `actions`, `isDismissible` → `Future<T?>` | Drag handle, titled header with labelled close, scrolls, keyboard-safe. Layout is `KSheetBody` |

### 3.7 Navigation and layout
| Component | Notes |
|---|---|
| `KScaffold` | `body`, `appBar?`, `banner?` (offline slot), `fab?`, `bottomBar?`, `padded` (gutter) |
| `KAppBar` | `title`, `subtitle?`, `actions`, `leading: KAppBarLeading{auto, back, close, none}`, `onLeading?`, `large`, `bottom?` |
| `KBottomNav` | Home · Inbox · Profile. `items: [KNavItem(icon, label, selectedIcon?, showDot)]`, `currentIndex`, `onTap` |
| `KTabBar` | Kameti detail tabs: Overview · Members · Schedule · Payments · Notes. `tabs: [String]`, `controller?` (else `DefaultTabController`), `onTap?`; use as `KAppBar.bottom` |
| `KSliverList` | Virtualised list with pull-to-refresh (E51) |
| `KPageHeader` | Big number + caption (e.g. "You owe Rs 2,50,000 this month") |

## 4. Rules for every component

1. **Tokens only.** No `Color(0x…)`, `Colors.*`, hard-coded `TextStyle`, `EdgeInsets` numbers or `BorderRadius` numbers. Read everything from `context.k`.
2. **Light and dark.** Every component is verified in both.
3. **Accessibility:**
   - 44×44 minimum touch target;
   - a `Semantics` label on every icon-only control;
   - status shown by **icon + text**, never colour alone;
   - works at text scale 2.0 without clipping (wrap or scale down, never truncate amounts);
   - RTL-safe: use `EdgeInsetsDirectional` and `AlignmentDirectional` (Urdu in v1.1).
4. **Stateless by default.** Components take values and callbacks; they don't fetch data or read Riverpod providers.
5. **`const` constructors** where possible, with named parameters and required ones marked `required`.
6. **Every state covered:** default, pressed, focused, disabled, loading, error, empty — whichever apply.
7. **Money** is always a `Money` (int rupees) value shown through `KMoneyText` / `KAmountField`. Never a `double`, never a pre-formatted `String`.
8. **Strings:** components take their text from callers (already localised). Built-in text such as "Retry" comes from l10n.
9. **Each component ships with:** a golden test (light + dark, text scale 1.0 and 2.0), a widget test for interaction, a Widgetbook use case for each variant and state, and a dartdoc comment with an example.
10. **No breaking API changes** without updating every call site in the same PR.

## 5. Adding or changing a component

Use the `ds-component` skill. Check first whether an existing component plus a new variant would do. Feature-specific one-offs stay in that feature's `presentation/widgets/` folder, built from KDS components, and are promoted to KDS only once a second feature needs them.
