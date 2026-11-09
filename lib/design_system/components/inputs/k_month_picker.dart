import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/components/buttons/k_icon_button.dart';
import 'package:kameti/design_system/components/feedback/k_sheet.dart';
import 'package:kameti/design_system/components/inputs/k_field_frame.dart';
import 'package:kameti/design_system/components/inputs/k_picker_button.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Month + year field (e.g. a kameti's first month). Tapping opens a sheet
/// with a year switcher and a 3×4 month grid; months outside
/// [firstMonth]–[lastMonth] are disabled.
///
/// Months are passed and returned as the first day of the month in UTC
/// (`DateTime.utc(2026, 10)`), matching `KametiClock.currentMonth()`.
///
/// ```dart
/// KMonthPicker(
///   label: l10n.firstMonth,
///   value: start,
///   firstMonth: clock.currentMonth(),
///   lastMonth: DateTime.utc(2030, 12),
///   onChanged: (m) => setState(() => start = m),
/// )
/// ```
class KMonthPicker extends StatelessWidget {
  const new({
    required this.value,
    required this.firstMonth,
    required this.lastMonth,
    required this.onChanged,
    this.label,
    this.hint,
    this.helper,
    this.error,
    super.key,
  });

  final DateTime? value;
  final DateTime firstMonth;
  final DateTime lastMonth;

  /// Null disables the field.
  final ValueChanged<DateTime>? onChanged;
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;

  Future<void> _pick(BuildContext context) async {
    final picked = await showKSheet<DateTime>(
      context,
      title: label ?? AppLocalizations.of(context).dsSelectMonth,
      builder: (context) => _MonthGrid(
        value: value,
        firstMonth: firstMonth,
        lastMonth: lastMonth,
        onSelected: (m) => Navigator.of(context).pop(m),
      ),
    );
    if (picked != null) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final v = value;
    return KFieldFrame(
      label: label,
      helper: helper,
      error: error,
      child: KPickerButton(
        text: v == null
            ? (hint ?? l10n.dsSelectMonth)
            : DateFormat.yMMMM(locale).format(v),
        placeholder: v == null,
        hasError: error != null,
        icon: Icons.calendar_month_outlined,
        onTap: onChanged == null ? null : () => _pick(context),
      ),
    );
  }
}

/// Year switcher and month grid shown inside [KMonthPicker]'s sheet.
class _MonthGrid extends StatefulWidget {
  const new({
    required this.value,
    required this.firstMonth,
    required this.lastMonth,
    required this.onSelected,
  });

  final DateTime? value;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<_MonthGrid> {
  late int _year = (widget.value ?? widget.firstMonth).year.clamp(
    widget.firstMonth.year,
    widget.lastMonth.year,
  );

  int _key(int year, int month) => year * 12 + month;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = _key(widget.firstMonth.year, widget.firstMonth.month);
    final last = _key(widget.lastMonth.year, widget.lastMonth.month);
    final selected = widget.value == null
        ? null
        : _key(widget.value!.year, widget.value!.month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            KIconButton(
              icon: Icons.chevron_left,
              semanticLabel: l10n.dsPreviousYear,
              onPressed: _year > widget.firstMonth.year
                  ? () => setState(() => _year--)
                  : null,
            ),
            Expanded(
              child: Text(
                '$_year',
                textAlign: TextAlign.center,
                style: k.text.title,
              ),
            ),
            KIconButton(
              icon: Icons.chevron_right,
              semanticLabel: l10n.dsNextYear,
              onPressed: _year < widget.lastMonth.year
                  ? () => setState(() => _year++)
                  : null,
            ),
          ],
        ),
        const KGap.sm(),
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: KSpace.sm),
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const KGap.sm(),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final month = row * 3 + col + 1;
                        final key = _key(_year, month);
                        final enabled = key >= first && key <= last;
                        final isSelected = key == selected;
                        final date = DateTime.utc(_year, month);
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          enabled: enabled,
                          label: DateFormat.yMMMM(locale).format(date),
                          onTap: enabled ? () => widget.onSelected(date) : null,
                          excludeSemantics: true,
                          child: Material(
                            color: isSelected ? c.brand : c.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                KRadius.input,
                              ),
                              side: BorderSide(
                                color: isSelected ? c.brand : c.border,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: enabled
                                  ? () => widget.onSelected(date)
                                  : null,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: KSize.inputHeight,
                                ),
                                child: Center(
                                  child: Text(
                                    DateFormat.MMM(locale).format(date),
                                    style: k.text.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? c.textOnBrand
                                          : enabled
                                          ? c.textPrimary
                                          : c.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
