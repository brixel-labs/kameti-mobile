import 'package:flutter/material.dart';
import 'package:kameti/design_system/theme/k_theme_x.dart';

enum KAvatarSize {
  sm(30),
  md(36),
  lg(48);

  new(this.dimension);

  final double dimension;
}

/// A member's round avatar: photo when [imageUrl] loads, initials on the
/// member's palette colour otherwise.
///
/// [colorIndex] picks from `context.k.colors.avatars` (wraps around), so
/// keep it stable per member (e.g. their position when they were added).
/// The avatar is decorative by default, since a name usually sits beside
/// it; pass [semanticLabel] when it stands alone.
///
/// ```dart
/// KAvatar(name: 'Usman Tariq', colorIndex: 2)   // "UT"
/// ```
class KAvatar extends StatelessWidget {
  const new({
    required this.name,
    required this.colorIndex,
    this.size = KAvatarSize.md,
    this.imageUrl,
    this.ringColor,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final int colorIndex;
  final KAvatarSize size;
  final String? imageUrl;

  /// Draws a 2 px ring (used by `KAvatarStack` to separate overlaps).
  final Color? ringColor;
  final String? semanticLabel;

  /// Up to two initials: first letters of the first and last words.
  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
    if (words.length == 1) return first(words.first);
    return first(words.first) + first(words.last);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final palette = k.colors.avatar(colorIndex);
    final d = size.dimension;
    final initials = Center(
      child: Text(
        initialsOf(name),
        textScaler: TextScaler.noScaling,
        style: k.text.caption.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w600,
          fontSize: d * 0.36,
          height: 1,
        ),
      ),
    );
    final avatar = Container(
      width: d,
      height: d,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.background,
        shape: BoxShape.circle,
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: 2),
      ),
      child: imageUrl == null
          ? initials
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initials,
            ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: avatar)
        : Semantics(
            image: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: avatar,
          );
  }
}
