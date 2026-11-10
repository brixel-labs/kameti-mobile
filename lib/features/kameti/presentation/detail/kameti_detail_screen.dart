import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/draft_view.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/edit_kameti_sheet.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/member_view.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/members_tab.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/notes_tab.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/overview_tab.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/payments_tab.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/schedule_tab.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One kameti: owner tabs (Overview, Members, Schedule, Payments, Notes;
/// boards A-Overview, A2-*-Tab) or the member's read-only view (boards
/// A-Member-View, AD-Member-View; FR-60–64).
///
/// Owner vs member is decided once, by `isKametiOwnerProvider`; the member
/// branch builds no write controls at all, and the backend enforces the
/// same rule.
class KametiDetailScreen extends ConsumerWidget {
  const new({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final kameti = ref.watch(kametiProvider(kametiId));
    final isOwner = ref.watch(isKametiOwnerProvider(kametiId));

    final k = kameti.value;
    final owner = isOwner.value;
    if (k == null || owner == null) {
      return KScaffold(
        appBar: KAppBar(title: k?.name ?? l10n.appTitle),
        body: AsyncGate(
          values: [kameti, isOwner],
          onRetry: () => refreshKameti(ref, kametiId),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      );
    }

    final subtitle = l10n.detailSubtitle(k.monthsN, k.slotAmountC.format());
    if (!owner) {
      return KScaffold(
        appBar: KAppBar(
          title: k.name,
          subtitle: subtitle,
          actions: [
            _ActivityButton(kametiId: k.id),
            _ViewOnlyPill(label: l10n.homeRoleViewOnly),
          ],
        ),
        body: MemberView(kameti: k),
      );
    }
    if (k.status == KametiStatus.draft) {
      return KScaffold(
        appBar: KAppBar(
          title: k.name,
          subtitle: subtitle,
          actions: [_EditButton(kameti: k)],
        ),
        body: DraftView(kameti: k),
      );
    }
    return _OwnerTabs(kameti: k, subtitle: subtitle);
  }
}

class _OwnerTabs extends StatelessWidget {
  const new({required this.kameti, required this.subtitle});

  final Kameti kameti;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 5,
      child: KScaffold(
        appBar: KAppBar(
          title: kameti.name,
          subtitle: subtitle,
          actions: [
            _ActivityButton(kametiId: kameti.id),
            _EditButton(kameti: kameti),
          ],
          bottom: KTabBar(
            tabs: [
              l10n.detailTabOverview,
              l10n.detailTabMembers,
              l10n.detailTabSchedule,
              l10n.detailTabPayments,
              l10n.detailTabNotes,
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(kameti: kameti),
            MembersTab(kameti: kameti),
            ScheduleTab(kameti: kameti),
            PaymentsTab(kameti: kameti),
            const NotesTab(),
          ],
        ),
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  const new({required this.kametiId});

  final String kametiId;

  @override
  Widget build(BuildContext context) => KIconButton(
    icon: Icons.history,
    semanticLabel: AppLocalizations.of(context).detailActivityAction,
    onPressed: () => context.push(Routes.activityFor(kametiId)),
  );
}

class _EditButton extends StatelessWidget {
  const new({required this.kameti});

  final Kameti kameti;

  @override
  Widget build(BuildContext context) => KIconButton(
    icon: Icons.edit_outlined,
    semanticLabel: AppLocalizations.of(context).kametiEditAction,
    onPressed: () => showEditKametiSheet(context, kameti: kameti),
  );
}

class _ViewOnlyPill extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.k.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: KSpace.sm),
      child: KPill(
        label: label,
        icon: Icons.visibility_outlined,
        foreground: c.textSecondary,
        background: c.surfaceSunken,
      ),
    );
  }
}
