import 'package:flutter/services.dart';
import 'package:kameti/core/money/money.dart';

/// Formats typed rupees with lakh grouping as you type (`2,50,000`).
///
/// Digits only: letters, signs, spaces and decimal points are dropped, and
/// leading zeros are removed. The caret stays after the same digit it was
/// after before regrouping. Used by `KAmountField` and `KShareSplitEditor`.
class KLakhInputFormatter extends TextInputFormatter {
  const new({this.maxDigits = 12});

  /// Longest number accepted (12 digits = up to Rs 9,99,99,99,99,999).
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final caret = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, raw.length)
        : raw.length;

    var digitsBeforeCaret = 0;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final ch = raw.codeUnitAt(i);
      if (ch < 0x30 || ch > 0x39) continue;
      buffer.writeCharCode(ch);
      if (i < caret) digitsBeforeCaret++;
    }

    var digits = buffer.toString();
    final leadingZeros =
        digits.length - digits.replaceFirst(RegExp('^0+'), '').length;
    digits = digits.substring(leadingZeros);
    digitsBeforeCaret = (digitsBeforeCaret - leadingZeros).clamp(
      0,
      digits.length,
    );

    if (digits.length > maxDigits) return oldValue;
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = format(Money(int.parse(digits)));
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCaret) {
      if (formatted.codeUnitAt(offset) != 0x2C) seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  /// The field text for [amount], without the `Rs` symbol (`2,50,000`).
  static String format(Money amount) => amount.format(symbol: false);
}
