import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Where a payout month is, for [KMonthTile].
enum KMonthTileState { upcoming, now, paidOut }

/// One month in the payout schedule grid (design A2-Schedule-Grid):
/// "NOV 26" over the recipients ("Ali + Sara").
///
/// - [KMonthTileState.paidOut]: filled brand, with a ✓;
/// - [KMonthTileState.now]: 2 px info outline and "· NOW";
/// - [isYourTurn]: amber highlight (combines with `now`).
///
/// Every state is also spelled out for screen readers. [selected] draws a
/// brand outline (the month whose details show below the grid).
///
/// ```dart
/// KMonthTile(month: DateTime.utc(2026, 11), recipients: 'Ali + Sara',
///     state: KMonthTileState.now, onTap: () => select(1))
/// ```
class KMonthTile extends StatelessWidget {
  const new({
    required this.month,
    required this.recipients,
    this.state = KMonthTileState.upcoming,
    this.isYourTurn = false,
    this.selected = false,
    this.onTap,
    super.key,
  });

  /// Any day in the month (only year and month are used).
  final DateTime month;

  /// Caller-localised recipient names, e.g. "Nida + You".
  final String recipients;
  final KMonthTileState state;
  final bool isYourTurn;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final paidOut = state == KMonthTileState.paidOut;
    final now = state == KMonthTileState.now;

    final monthText = DateFormat('MMM yy', locale).format(month).toUpperCase();
    final header = now
        ? '$monthText · ${l10n.dsScheduleNow.toUpperCase()}'
        : monthText;

    final Color bg;
    final Color headerColor;
    final Color bodyColor;
    if (paidOut) {
      bg = c.brand;
      headerColor = c.textOnBrand.withValues(alpha: 0.8);
      bodyColor = c.textOnBrand;
    } else if (isYourTurn) {
      bg = c.yourTurn;
      headerColor = c.warning;
      bodyColor = c.onYourTurn;
    } else {
      bg = c.surface;
      headerColor = now ? c.info : c.textSecondary;
      bodyColor = c.textPrimary;
    }

    final BorderSide border;
    if (now) {
      border = BorderSide(color: c.info, width: 2);
    } else if (selected) {
      border = BorderSide(color: c.brand, width: 2);
    } else if (paidOut) {
      border = BorderSide(color: c.brand);
    } else if (isYourTurn) {
      border = BorderSide(color: c.yourTurnBorder);
    } else {
      border = BorderSide(color: c.border);
    }

    final semantics = [
      DateFormat.yMMMM(locale).format(month),
      recipients,
      if (paidOut) l10n.dsSchedulePaidOut,
      if (now) l10n.dsScheduleNow,
      if (isYourTurn) l10n.dsScheduleYourTurn,
    ].join(', ');

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semantics,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KRadius.input),
          side: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: KSize.monthTile),
            padding: const EdgeInsetsDirectional.all(KSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  header,
                  style: k.text.caption.copyWith(
                    color: headerColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const KGap.xs(),
                Text.rich(
                  TextSpan(
                    text: recipients,
                    children: [
                      if (paidOut)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: KSpace.xxs,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 13,
                              color: bodyColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: k.text.caption.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
