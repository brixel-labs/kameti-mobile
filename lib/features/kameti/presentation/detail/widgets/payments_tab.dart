import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/detail/detail_refresh.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_view_data.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/detail_list.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/payment_row.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/void_payment_sheet.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Owner's Payments tab (board A2-Payments-Tab): this month's received
/// total and every payment, newest first. Tapping a payment opens the void
/// sheet; voided payments stay in the list, struck through.
class PaymentsTab extends ConsumerWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = kameti.id;
    final payments = ref.watch(kametiPaymentsProvider(id));
    final members = ref.watch(kametiMembersProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));
    return AsyncGate(
      values: [payments, members, collections],
      onRetry: () => refreshKameti(ref, id),
      builder: (context, offline) {
        final list = members.requireValue;
        final byId = {for (final m in list) m.id: m};
        final sorted = [...payments.requireValue]
          ..sort((a, b) {
            final byDate = b.receivedOn.compareTo(a.receivedOn);
            return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
          });
        final current = currentCollection(collections.requireValue);

        if (sorted.isEmpty) {
          return DetailList(
            kametiId: id,
            offline: offline,
            children: [
              KEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.detailNoPaymentsTitle,
                message: l10n.detailNoPaymentsBody,
              ),
            ],
          );
        }

        final valid = sorted.where((p) => !p.isVoided).length;
        return DetailList(
          kametiId: id,
          offline: offline,
          children: [
            KCard(
              child: KKeyValueList(
                items: [
                  if (current != null)
                    KKeyValue(
                      l10n.detailReceived,
                      amount: current.received,
                      emphasis: true,
                    ),
                  KKeyValue(
                    l10n.detailTabPayments,
                    value: l10n.detailPaymentsCount(valid),
                  ),
                ],
              ),
            ),
            const KGap.lg(),
            for (final (i, p) in sorted.indexed)
              _row(context, p, byId[p.memberId], list, i < sorted.length - 1),
          ],
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    Payment p,
    Member? member,
    List<Member> members,
    bool divider,
  ) {
    final name = member?.name ?? '';
    return PaymentRow(
      payment: p,
      title: name,
      leading: member == null
          ? null
          : KAvatar(name: name, colorIndex: colorIndexOf(member, members)),
      showDivider: divider,
      onTap: p.isVoided
          ? null
          : () => showVoidPaymentSheet(context, payment: p, memberName: name),
    );
  }
}
