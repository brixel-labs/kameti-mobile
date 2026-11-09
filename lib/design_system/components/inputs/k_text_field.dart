import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kameti/design_system/components/inputs/k_field_frame.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';

/// The base text input: label above, helper or error below, 48 px field.
///
/// Pass [error] to show a validation message (it wins over [helper]); or
/// pass a [validator] when the field sits in a `Form`.
///
/// ```dart
/// KTextField(
///   label: l10n.kametiName,
///   helper: l10n.kametiNameHelper,
///   controller: nameController,
/// )
/// ```
class KTextField extends StatelessWidget {
  const new({
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.prefix,
    this.suffix,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;

  /// Only used when [controller] is null.
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLength;
  final int? maxLines;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KFieldFrame(
      label: label,
      helper: helper,
      error: error,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLines: maxLines,
        enabled: enabled,
        autofocus: autofocus,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        style: k.text.body.copyWith(
          color: enabled ? k.colors.textPrimary : k.colors.textTertiary,
        ),
        decoration: kInputDecoration(
          context,
          hint: hint,
          prefix: prefix,
          suffix: suffix,
          hasError: error != null,
        ).copyWith(semanticCounterText: ''),
      ),
    );
  }
}
