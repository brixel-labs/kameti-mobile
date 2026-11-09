import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';

/// A scrollable tab body with pull to refresh (E51) and the screen gutter.
/// [offline] (from `AsyncGate`) sits at the top.
class DetailList extends ConsumerWidget {
  const new({
    required this.kametiId,
    required this.children,
    this.offline,
    super.key,
  });

  final String kametiId;
  final List<Widget> children;
  final Widget? offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    color: context.k.colors.brand,
    onRefresh: () => refreshKameti(ref, kametiId),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpace.gutter,
        KSpace.lg,
        KSpace.gutter,
        KSpace.xxxl,
      ),
      children: [
        if (offline != null) ...[offline!, const KGap.md()],
        ...children,
      ],
    ),
  );
}
