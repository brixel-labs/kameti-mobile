import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/display/k_avatar.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// The data one avatar needs (used by [KAvatarStack]).
@immutable
class KAvatarData {
  const new({required this.name, required this.colorIndex, this.imageUrl});

  final String name;
  final int colorIndex;
  final String? imageUrl;
}

/// Overlapping avatars for a shared slot's recipients, with a "+2" bubble
/// past [max].
///
/// Screen readers hear the names joined, plus "2 more". Pass [ringColor]
/// matching the surface behind the stack (defaults to `surface`).
///
/// ```dart
/// KAvatarStack(members: [KAvatarData(name: 'Ali Raza', colorIndex: 0), ...])
/// ```
class KAvatarStack extends StatelessWidget {
  const new({
    required this.members,
    this.max = 3,
    this.size = KAvatarSize.sm,
    this.ringColor,
    super.key,
  }) : assert(max > 0, 'max must be at least 1');

  final List<KAvatarData> members;
  final int max;
  final KAvatarSize size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final ring = ringColor ?? k.colors.surface;
    final shown = members.take(max).toList();
    final extra = members.length - shown.length;
    final d = size.dimension;
    final overlap = d * 0.27;
    final count = shown.length + (extra > 0 ? 1 : 0);
    final l10n = AppLocalizations.of(context);
    final label = [
      ...shown.map((m) => m.name),
      if (extra > 0) l10n.dsMoreCount(extra),
    ].join(', ');

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: count == 0 ? 0 : d + (count - 1) * (d - overlap),
        height: d,
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              PositionedDirectional(
                start: i * (d - overlap),
                child: KAvatar(
                  name: shown[i].name,
                  colorIndex: shown[i].colorIndex,
                  imageUrl: shown[i].imageUrl,
                  size: size,
                  ringColor: ring,
                ),
              ),
            if (extra > 0)
              PositionedDirectional(
                start: shown.length * (d - overlap),
                child: Container(
                  width: d,
                  height: d,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: k.colors.surfaceSunken,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2),
                  ),
                  child: Text(
                    '+$extra',
                    textScaler: TextScaler.noScaling,
                    style: k.text.caption.copyWith(
                      color: k.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: d * 0.36,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
