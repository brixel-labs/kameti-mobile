import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// "Oct 2026" ([long]: "October 2026") in the app locale.
String monthLabel(BuildContext context, DateTime month, {bool long = false}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return (long ? DateFormat.yMMMM(locale) : DateFormat.yMMM(locale)).format(
    month,
  );
}

/// The month of a 1-based [index] in a kameti starting in [startMonth].
DateTime monthAt(DateTime startMonth, int index) =>
    DateTime.utc(startMonth.year, startMonth.month + index - 1);

/// "Omar", "Omar and Rabia", "Omar, Sana and Rabia".
String joinNames(AppLocalizations l10n, List<String> names) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  return l10n.createNamesAnd(
    names.sublist(0, names.length - 1).join(', '),
    names.last,
  );
}

/// "10th".
String dayOrdinal(AppLocalizations l10n, int day) =>
    l10n.createDayOrdinal('$day');
