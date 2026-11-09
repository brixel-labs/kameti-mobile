import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/inputs/k_toggle_tile_body.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';

/// A setting row with a switch at the end. The whole row toggles.
/// `onChanged: null` disables it.
///
/// ```dart
/// KSwitchTile(title: l10n.remindMembers, value: on, onChanged: setOn)
/// ```
class KSwitchTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    return MergeSemantics(
      child: KToggleTileBody(
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        control: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: c.textOnBrand,
          activeTrackColor: c.brand,
          inactiveThumbColor: c.textTertiary,
          inactiveTrackColor: c.surfaceSunken,
          trackOutlineColor: WidgetStatePropertyAll(c.borderStrong),
        ),
      ),
    );
  }
}
