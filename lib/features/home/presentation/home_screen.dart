import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/home/presentation/widgets/home_kameti_card.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Home (boards Main, AF-Empty-Home, AD-Home; FR-1–3): "Running by me",
/// "I'm a member" and "Past", or the first-time empty state.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myKametisProvider);
    try {
      await ref.read(myKametisProvider.future);
    } on Object {
      // Shown by the error state or the offline banner.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kametis = ref.watch(myKametisProvider);
    final userId = ref.watch(currentUserIdProvider);
    return KScaffold(
      appBar: KAppBar(
        title: l10n.appTitle,
        large: true,
        actions: [
          KIconButton(
            icon: Icons.person_outline,
            semanticLabel: l10n.profileOpen,
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: AsyncGate(
        values: [kametis, userId],
        onRetry: () => _refresh(ref),
        builder: (context, offline) => RefreshIndicator(
          color: context.k.colors.brand,
          onRefresh: () => _refresh(ref),
          child: _HomeList(
            kametis: kametis.requireValue,
            userId: userId.requireValue,
            offline: offline,
          ),
        ),
      ),
    );
  }
}

class _HomeList extends StatelessWidget {
  const new({
    required this.kametis,
    required this.userId,
    required this.offline,
  });

  final List<Kameti> kametis;
  final String? userId;
  final Widget? offline;

  static bool _isPast(Kameti k) => const {
    KametiStatus.completed,
    KametiStatus.archived,
    KametiStatus.cancelled,
  }.contains(k.status);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void create() => context.push(Routes.createKameti);

    final past = kametis.where(_isPast).toList();
    final live = kametis.where((k) => !_isPast(k));
    final mine = live.where((k) => k.isOwnedBy(userId)).toList();
    final joined = live.where((k) => !k.isOwnedBy(userId)).toList();

    Widget card(Kameti k, {required bool owner}) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: KSpace.md),
      child: HomeKametiCard(
        kameti: k,
        isOwner: owner,
        userId: userId,
        onTap: () => context.push(Routes.kameti(k.id)),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpace.gutter,
        KSpace.sm,
        KSpace.gutter,
        KSpace.xxxl,
      ),
      children: [
        if (offline != null) ...[offline!, const KGap.md()],
        if (kametis.isEmpty)
          KCard(
            child: KEmptyState(
              icon: Icons.donut_large_outlined,
              title: l10n.homeEmptyTitle,
              message: l10n.homeEmptyBody,
              actionLabel: l10n.startKameti,
              onAction: create,
            ),
          ),
        if (mine.isNotEmpty || joined.isEmpty && kametis.isNotEmpty) ...[
          KSectionHeader(
            title: l10n.homeRunningByMe,
            actionLabel: l10n.homeNewKameti,
            onAction: create,
          ),
          for (final k in mine) card(k, owner: true),
        ],
        if (joined.isNotEmpty) ...[
          if (mine.isEmpty)
            KSectionHeader(
              title: l10n.homeImAMember,
              actionLabel: l10n.homeNewKameti,
              onAction: create,
            )
          else
            KSectionHeader(title: l10n.homeImAMember),
          for (final k in joined) card(k, owner: false),
        ],
        if (past.isNotEmpty) ...[
          KSectionHeader(title: l10n.homePast),
          for (final k in past) card(k, owner: k.isOwnedBy(userId)),
        ],
      ],
    );
  }
}
