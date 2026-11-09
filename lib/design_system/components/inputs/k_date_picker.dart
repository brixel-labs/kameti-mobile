import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kameti/design_system/components/inputs/k_field_frame.dart';
import 'package:kameti/design_system/components/inputs/k_picker_button.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// A date field that opens the date picker. Dates after [lastDate] can't
/// be picked, so a payment date is never in the future (FR-46).
///
/// [lastDate] is required (pass `clock.now()` from `KametiClock`): the
/// design system never reads the device clock. A [value] after [lastDate]
/// shows a built-in error.
///
/// ```dart
/// KDatePicker(
///   label: l10n.dateReceived,
///   value: date,
///   lastDate: clock.now(),
///   onChanged: (d) => setState(() => date = d),
/// )
/// ```
class KDatePicker extends StatelessWidget {
  const new({
    required this.value,
    required this.lastDate,
    required this.onChanged,
    this.firstDate,
    this.label,
    this.hint,
    this.helper,
    this.error,
    super.key,
  });

  final DateTime? value;

  /// Latest pickable day (inclusive), normally today in Pakistan time.
  final DateTime lastDate;

  /// Earliest pickable day. Defaults to ten years before [lastDate].
  final DateTime? firstDate;

  /// Called with the picked day (time part zero). Null disables the field.
  final ValueChanged<DateTime>? onChanged;
  final String? label;

  /// Shown while [value] is null. Defaults to "Select date".
  final String? hint;
  final String? helper;
  final String? error;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whether [value] is after [lastDate] (day precision).
  static bool isAfterLast(DateTime value, DateTime lastDate) =>
      _day(value).isAfter(_day(lastDate));

  Future<void> _pick(BuildContext context) async {
    final last = _day(lastDate);
    final first = _day(
      firstDate ?? DateTime(last.year - 10, last.month, last.day),
    );
    var initial = _day(value ?? last);
    if (initial.isAfter(last)) initial = last;
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged?.call(_day(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final v = value;
    final builtIn = v != null && isAfterLast(v, lastDate)
        ? l10n.dsDateInFuture
        : null;
    final shownError = error ?? builtIn;
    return KFieldFrame(
      label: label,
      helper: helper,
      error: shownError,
      child: KPickerButton(
        text: v == null
            ? (hint ?? l10n.dsSelectDate)
            : DateFormat.yMMMd(locale).format(v),
        placeholder: v == null,
        hasError: shownError != null,
        icon: Icons.calendar_today_outlined,
        onTap: onChanged == null ? null : () => _pick(context),
      ),
    );
  }
}
