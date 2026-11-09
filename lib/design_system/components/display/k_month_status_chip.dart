import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/display/k_pill.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Where a kameti month is in its cycle.
enum KMonthStatus { upcoming, collecting, collected, paidOut, paidOutShort }

/// A month's status, with icon and text ("Collecting", "Paid out").
///
/// The label is built in (l10n); pass [label] to override it.
///
/// ```dart
/// const KMonthStatusChip(status: KMonthStatus.collecting)
/// ```
class KMonthStatusChip extends StatelessWidget {
  const new({required this.status, this.label, super.key});

  final KMonthStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    final l10n = AppLocalizations.of(context);
    final (fg, bg, icon, text) = switch (status) {
      KMonthStatus.upcoming => (
        c.textSecondary,
        c.surfaceSunken,
        Icons.schedule,
        l10n.dsMonthUpcoming,
      ),
      KMonthStatus.collecting => (
        c.info,
        c.infoSubtle,
        Icons.hourglass_bottom,
        l10n.dsMonthCollecting,
      ),
      KMonthStatus.collected => (
        c.positive,
        c.positiveSubtle,
        Icons.check,
        l10n.dsMonthCollected,
      ),
      KMonthStatus.paidOut => (
        c.onBrandSubtle,
        c.brandSubtle,
        Icons.done_all,
        l10n.dsMonthPaidOut,
      ),
      KMonthStatus.paidOutShort => (
        c.warning,
        c.warningSubtle,
        Icons.warning_amber,
        l10n.dsMonthPaidOutShort,
      ),
    };
    return KPill(
      label: label ?? text,
      foreground: fg,
      background: bg,
      icon: icon,
    );
  }
}
