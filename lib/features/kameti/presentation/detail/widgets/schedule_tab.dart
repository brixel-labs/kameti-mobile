import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/schedule_section.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';

/// Owner's Schedule tab (board A2-Schedule-Grid), with "Pay out" on a
/// started month.
class ScheduleTab extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = kameti.id;
    final members = ref.watch(kametiMembersProvider(id));
    final slots = ref.watch(kametiSlotsProvider(id));
    final shares = ref.watch(kametiSharesProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));
    final userId = ref.watch(currentUserIdProvider).value;
    return AsyncGate(
      values: [members, slots, shares, collections],
      onRetry: () => refreshKameti(ref, id),
      builder: (context, offline) => DetailList(
        kametiId: id,
        offline: offline,
        children: [
          ScheduleSection(
            kameti: kameti,
            members: members.requireValue,
            slots: slots.requireValue,
            shares: shares.requireValue,
            collections: collections.requireValue,
            myMemberId: myMemberRow(members.requireValue, userId)?.id,
            canPayOut: true,
          ),
        ],
      ),
    );
  }
}
