import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/kameti/k_month_tile.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One month in a [KScheduleGrid].
@immutable
class KScheduleMonth {
  const new({
    required this.month,
    required this.recipients,
    this.state = KMonthTileState.upcoming,
    this.isYourTurn = false,
  });

  final DateTime month;

  /// Caller-localised recipient names ("Ali + Sara").
  final String recipients;
  final KMonthTileState state;
  final bool isYourTurn;
}

/// Payout schedule as a grid of [KMonthTile]s, four per row, with a legend
/// (Paid out · Now · Your turn). Tapping a tile reports its index; show
/// that month's recipients below the grid yourself.
///
/// Rows grow with the text size, so long names at text scale 2.0 wrap
/// instead of clipping. The grid isn't scrollable; put it in the screen's
/// scroll view.
///
/// ```dart
/// KScheduleGrid(
///   months: schedule.map((s) => KScheduleMonth(...)).toList(),
///   selectedIndex: selected,
///   onSelect: (i) => setState(() => selected = i),
/// )
/// ```
class KScheduleGrid extends StatelessWidget {
  const new({
    required this.months,
    this.selectedIndex,
    this.onSelect,
    this.showLegend = true,
    this.columns = 4,
    super.key,
  });

  final List<KScheduleMonth> months;
  final int? selectedIndex;
  final ValueChanged<int>? onSelect;
  final bool showLegend;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < months.length; start += columns) {
      if (start > 0) rows.add(const KGap.sm());
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < start + columns; i++) ...[
                if (i > start) const KGap.sm(),
                Expanded(
                  child: i < months.length
                      ? KMonthTile(
                          month: months[i].month,
                          recipients: months[i].recipients,
                          state: months[i].state,
                          isYourTurn: months[i].isYourTurn,
                          selected: i == selectedIndex,
                          onTap: onSelect == null ? null : () => onSelect!(i),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLegend) ...[const _Legend(), const KGap.md()],
        ...rows,
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    Widget item(String label, BoxDecoration swatch) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: KSpace.md, height: KSpace.md, decoration: swatch),
        const KGap(KSpace.xs + KSpace.xxs),
        Text(label, style: k.text.caption.copyWith(color: c.textSecondary)),
      ],
    );
    final radius = BorderRadius.circular(KRadius.sm / 2);
    return ExcludeSemantics(
      child: Wrap(
        spacing: KSpace.md + KSpace.xxs,
        runSpacing: KSpace.xs,
        children: [
          item(
            l10n.dsSchedulePaidOut,
            BoxDecoration(color: c.brand, borderRadius: radius),
          ),
          item(
            l10n.dsScheduleNow,
            BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: c.info, width: 2),
            ),
          ),
          item(
            l10n.dsScheduleYourTurn,
            BoxDecoration(
              color: c.yourTurn,
              borderRadius: radius,
              border: Border.all(color: c.yourTurnBorder),
            ),
          ),
        ],
      ),
    );
  }
}
