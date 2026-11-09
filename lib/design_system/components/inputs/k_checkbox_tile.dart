import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/inputs/k_toggle_tile_body.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';

/// A row with a checkbox at the start. The whole row toggles.
/// `onChanged: null` disables it.
///
/// ```dart
/// KCheckboxTile(title: member.name, value: picked, onChanged: toggle)
/// ```
class KCheckboxTile extends StatelessWidget {
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
        controlFirst: true,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        control: Checkbox(
          value: value,
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
          activeColor: c.brand,
          checkColor: c.textOnBrand,
          side: BorderSide(color: c.borderStrong, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KRadius.sm - 2),
          ),
        ),
      ),
    );
  }
}
