import 'package:flutter/material.dart';
import 'package:kameti/design_system/components/layout/k_card.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';
import 'package:kameti/design_system/tokens/k_dimens.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Placeholder block shown while content loads. No full-screen spinners
/// for content: lay out skeletons in the shape of what's coming.
///
/// Static (no shimmer), so `pumpAndSettle` in screen tests never hangs on
/// a loading state. Single blocks are hidden from screen readers; wrap a
/// group in [KSkeletonList] (or your own `Semantics(label: …)`) so
/// "Loading" is announced once.
///
/// ```dart
/// const KSkeleton(width: 120, height: 12)
/// const KSkeleton.circle(size: 36)
/// ```
class KSkeleton extends StatelessWidget {
  const new({
    this.width,
    this.height = KSpace.md,
    this.radius = KRadius.sm,
    super.key,
  });

  const new circle({required double size, super.key})
    : width = size,
      height = size,
      radius = KRadius.pill;

  /// Null fills the available width.
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.k.colors.surfaceSunken,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A card of [rows] loading rows (avatar, two text lines, a chip), the
/// standard list placeholder. Announced as "Loading".
class KSkeletonList extends StatelessWidget {
  const new({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).dsLoading,
      container: true,
      child: KCard(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0) const KGap.md(),
              Row(
                children: [
                  const KSkeleton.circle(size: 36),
                  const KGap.md(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: i.isEven ? 0.6 : 0.5,
                          child: const KSkeleton(),
                        ),
                        const KGap(KSpace.xs + KSpace.xxs),
                        FractionallySizedBox(
                          widthFactor: i.isEven ? 0.4 : 0.35,
                          child: const KSkeleton(
                            height: KSpace.sm + KSpace.xxs,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const KGap.md(),
                  const KSkeleton(
                    width: KSpace.xxxl + KSpace.sm,
                    height: KSpace.lg + KSpace.xs,
                    radius: KRadius.pill,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
