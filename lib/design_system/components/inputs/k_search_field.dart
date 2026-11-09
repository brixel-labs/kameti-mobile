import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/buttons/k_icon_button.dart';
import 'package:kameti/design_system/components/inputs/k_field_frame.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Search box with a leading search icon and a clear button.
///
/// [onChanged] is debounced ([debounce], default 250 ms); clearing calls it
/// at once with an empty string.
///
/// ```dart
/// KSearchField(hint: l10n.searchMembers(15), onChanged: controller.filter)
/// ```
class KSearchField extends StatefulWidget {
  const new({
    required this.onChanged,
    this.hint,
    this.debounce = const Duration(milliseconds: 250),
    this.autofocus = false,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final Duration debounce;
  final bool autofocus;

  @override
  State<KSearchField> createState() => _KSearchFieldState();
}

class _KSearchFieldState extends State<KSearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: k.text.body.copyWith(color: k.colors.textPrimary),
      decoration: kInputDecoration(
        context,
        hint: widget.hint ?? l10n.dsSearch,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          vertical: KSpace.md,
        ),
        prefix: Icon(Icons.search, size: 20, color: k.colors.textSecondary),
        suffix: _controller.text.isEmpty
            ? null
            : KIconButton(
                icon: Icons.close,
                semanticLabel: l10n.dsClearSearch,
                onPressed: _clear,
                size: 18,
              ),
      ),
    );
  }
}
