import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// What the owner sees for a kameti that hasn't started (FR-11): a summary
/// of what's set so far and "Continue setup", which reopens the create
/// wizard on this draft so it can be finished and started.
class DraftView extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final members = ref.watch(kametiMembersProvider(kameti.id));
    return AsyncGate(
      values: [members],
      onRetry: () => refreshKameti(ref, kameti.id),
      builder: (context, offline) => DetailList(
        kametiId: kameti.id,
        offline: offline,
        children: [
          KEmptyState(
            icon: Icons.edit_note,
            title: l10n.detailDraftTitle,
            message: l10n.detailDraftBody,
          ),
          const KGap.lg(),
          KCard(
            child: KKeyValueList(
              items: [
                KKeyValue(
                  l10n.detailDraftSummaryMonths,
                  value: '${kameti.monthsN}',
                ),
                KKeyValue(
                  l10n.detailDraftSummarySlot,
                  amount: kameti.slotAmountC,
                ),
                KKeyValue(
                  l10n.detailDraftSummaryPot,
                  amount: kameti.pot,
                  emphasis: true,
                ),
                KKeyValue(
                  l10n.detailDraftSummaryStart,
                  value: DateFormat.yMMMM(locale).format(kameti.startMonth),
                ),
                KKeyValue(
                  l10n.detailDraftSummaryDue,
                  value: '${kameti.dueDay}',
                ),
                KKeyValue(
                  l10n.detailDraftSummaryMembers,
                  value: '${members.requireValue.length}',
                ),
              ],
            ),
          ),
          const KGap.lg(),
          KButton.primary(
            label: l10n.detailContinueSetup,
            icon: Icons.arrow_forward,
            expand: true,
            onPressed: () => context.push(Routes.setup(kameti.id)),
          ),
        ],
      ),
    );
  }
}
