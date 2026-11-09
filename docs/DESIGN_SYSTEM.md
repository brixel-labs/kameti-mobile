# Kameti Design System (KDS)

Every screen in the app is built from these components. A screen never styles raw Flutter widgets itself.

> **Status:** structure and component APIs are defined. **Token values (colours, fonts, radii) are filled in after a design direction is chosen** in the design phase. Until then, components read from `KTheme` placeholders.

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
| **Colour: member palette** | `avatar1` … `avatar8`: distinct, AA-contrast colours for member avatars |
| **Typography** | `displayLg` (big money figures), `display`, `titleLg`, `title`, `titleSm`, `body`, `bodyStrong`, `bodySm`, `label`, `caption`, `mono` (amounts in tables, tabular figures) |
| **Spacing** | `xxs 2`, `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`, `xxxl 48` |
| **Radius** | `sm 6`, `md 10`, `lg 16`, `xl 24`, `pill 999` |
| **Elevation** | `none`, `low`, `mid`, `high` |
| **Motion** | `fast 120ms`, `base 200ms`, `slow 320ms`; curves `standard`, `emphasized` |
| **Layout** | screen gutter = `lg`; min touch target 44×44; max content width 600 (tablets later) |

Every colour pair used for text must pass **WCAG AA** in both light and dark.

## 3. Components

Naming: `K` + PascalCase. One public widget per file, `snake_case` file name (`k_button.dart`).

### 3.1 Buttons
| Component | Variants / API | Notes |
|---|---|---|
| `KButton` | `.primary`, `.secondary`, `.tertiary`, `.destructive`; `label`, `onPressed`, `icon?`, `isLoading`, `size: sm/md/lg`, `expand` | `onPressed: null` = disabled. Loading shows a spinner and ignores taps (prevents double payments) |
| `KIconButton` | `icon`, `onPressed`, `semanticLabel` (required), `variant` | |
| `KFab` | `icon`, `label?`, `onPressed` | Owner's main action, e.g. "Record payment" |
| `KTextLink` | `label`, `onTap` | Inline link |

### 3.2 Inputs
| Component | API | Notes |
|---|---|---|
| `KTextField` | `label`, `hint?`, `helper?`, `error?`, `controller`, `validator`, `keyboardType`, `prefix?`, `suffix?`, `maxLength?` | Base for all inputs |
| `KAmountField` | `label`, `value: Money?`, `onChanged`, `step` (default Rs 1,000), `min?`, `max?` | Shows `Rs` prefix, lakh grouping as you type, digits only, never decimals |
| `KSearchField` | `onChanged`, `hint` | Debounced 250 ms |
| `KMonthPicker` | `value`, `firstMonth`, `lastMonth`, `onChanged` | Month + year only |
| `KDatePicker` | `value`, `lastDate` (default today), `onChanged` | Payment dates can't be in the future (FR-46) |
| `KDropdown<T>` / `KSelectSheet<T>` | `items`, `value`, `itemLabel`, `onChanged` | Opens a bottom sheet on mobile |
| `KMemberPicker` | `members`, `selected`, `multi: bool`, `onChanged` | Search, avatars, "select all not invited" |
| `KSegmentedControl<T>` | `segments`, `value`, `onChanged` | e.g. Cash / Bank / Other |
| `KSwitchTile`, `KCheckboxTile`, `KRadioTile<T>` | `title`, `subtitle?`, `value`, `onChanged` | |
| `KStepper` | `steps`, `currentIndex` | Create-kameti wizard header |

### 3.3 Money (core to this app)
| Component | API | Notes |
|---|---|---|
| `KMoneyText` | `amount: Money`, `style: display/title/body/mono`, `compact: bool`, `signed: bool`, `tone: auto/neutral/positive/negative` | **The only way to show an amount.** Formats `Rs 24,00,000`; compact `24 L` / `2.4 Cr`. `signed` shows `+` / `−` for credit and dues |
| `KBalancePill` | `balance: Money` | Positive balance = "Owes Rs X" (negative tone); zero = "Settled"; negative balance = "Credit Rs X" (info tone) |
| `KPotProgress` | `collected`, `target`, `showLabels` | "Rs 23,50,000 of 50,00,000 · 47%"; flags overpayment |
| `KShareSplitEditor` | `slotAmount`, `shares`, `members`, `maxSharers` (4), `step`, `onChanged` | Presets ½+½, ⅓×3, ¼×4, ½+¼+¼, custom; live "Rs X left to assign"; blocks invalid sums |
| `KAmountSummaryRow` | `label`, `amount`, `emphasis` | Label/value rows in summaries and receipts |

### 3.4 Display
| Component | API | Notes |
|---|---|---|
| `KCard` | `child`, `onTap?`, `padding`, `variant: flat/raised/outlined` | |
| `KListTile` | `leading?`, `title`, `subtitle?`, `trailing?`, `onTap?` | Base row |
| `KAvatar` | `name`, `imageUrl?`, `colorIndex`, `size: sm/md/lg` | Initials fallback; colour stays the same per member |
| `KAvatarStack` | `members`, `max` (3) | Shared slot recipients, "+2" overflow |
| `KStatusChip` | `KPaymentStatus` {paid, partial, unpaid, overdue, advance, upcoming} | Icon + text, **never colour alone** |
| `KMonthStatusChip` | `KMonthStatus` {upcoming, collecting, collected, paidOut, paidOutShort} | |
| `KInviteStatusChip` | `KJoinStatus` {notInvited, invited, pendingApproval, joined, declined, expired, bounced} | |
| `KBadge` | `count` or `dot` | Inbox, approvals |
| `KSectionHeader` | `title`, `action?` | |
| `KDivider` | — | |
| `KInfoBanner` | `tone: info/warning/negative/positive`, `message`, `action?` | e.g. offline "Last updated 10:42", "3 members haven't paid" |
| `KKeyValueList` | `items` | Detail screens |

### 3.5 Kameti-specific (built only from the components above)
| Component | Shows |
|---|---|
| `KKametiCard` | Home card: name, role badge (Owner/Member), "Month 2 of 20", this month's recipient(s), your due status, pot progress |
| `KSlotTile` | Payout month, recipient avatar stack, shares, month status; drag handle when reorderable; lock icon when paid out |
| `KMemberRow` | Avatar, name/nickname, monthly due, balance pill, invite status (owner) |
| `KPaymentRow` | Date, amount, method, "paid by" note, void state (struck through + "Voided") |
| `KPayoutRow` | Recipient, amount, date, expected vs actual |
| `KMonthGridCell` / `KMonthGrid` | Spreadsheet-like members × months grid, status per cell, horizontal scroll, pinned first column |
| `KScheduleTimeline` | Vertical payout schedule with "You" highlighted and today's month marked |
| `KNoteTile` | Note text, author, time, Private/Shared tag |
| `KAuditTile` | Who did what, when, before → after |
| `KReminderCard` | Next reminder date, "Remind unpaid members" with sent-today state |

### 3.6 Feedback
| Component | API | Notes |
|---|---|---|
| `KEmptyState` | `illustration?`, `title`, `message`, `action?` | Every list has one |
| `KErrorState` | `message`, `onRetry` | |
| `KSkeleton` / `KSkeletonList` | shape presets | Loading: no full-screen spinners for content |
| `KLoadingOverlay` | `isLoading` | Blocking writes only |
| `KToast` (`context.showToast`) | `message`, `tone`, `action?` | Snackbar replacement, e.g. "Payment recorded · Undo" |
| `KConfirmDialog` | `title`, `message`, `confirmLabel`, `destructive` | Required before void, unlink, reorder after start, payout with shortfall |
| `KBottomSheet` (`showKSheet`) | `title`, `child`, `actions` | |

### 3.7 Navigation and layout
| Component | Notes |
|---|---|
| `KScaffold` | Safe areas, gutter, background, offline banner slot, FAB slot |
| `KAppBar` | `title`, `subtitle?`, `actions`, back behaviour, large-title variant |
| `KBottomNav` | Home · Inbox · Profile |
| `KTabBar` | Kameti detail tabs: Overview · Members · Schedule · Payments · Notes |
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
