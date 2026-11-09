import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/payments_controller.dart';
import 'package:kameti/features/payments/presentation/widgets/payments_widgets.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Someone who still owes this month, as shown in tap to settle.
@immutable
class SettleEntry {
  const new({
    required this.member,
    required this.colorIndex,
    required this.owed,
  });

  final Member member;
  final int colorIndex;

  /// Everything the member owes now (arrears included), so one tap
  /// settles them.
  final Money owed;
}

/// Everyone with something left to pay this month, in member order.
List<SettleEntry> settleEntries(
  List<Member> members,
  List<MemberBalanceRow> balances,
  List<MemberMonthRow> months,
) {
  final remaining = {
    for (final m in months)
      if (m.isCurrent && m.remaining.isPositive) m.memberId: m.remaining,
  };
  final owes = {for (final b in balances) b.memberId: b.owes};
  return [
    for (final (i, m) in members.indexed)
      if (remaining[m.id] case final rest?)
        SettleEntry(
          member: m,
          colorIndex: i,
          owed: (owes[m.id] ?? Money.zero) > rest ? owes[m.id]! : rest,
        ),
  ];
}

/// Record many at once: tap to settle (board A2-Bulk-Confirm, FR-43).
/// Nothing is written until Save, which records every marked payment in
/// one transaction.
class SettleScreen extends ConsumerStatefulWidget {
  const new({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends ConsumerState<SettleScreen> {
  /// Marked amounts by member id, in marking order.
  final Map<String, Money> _marked = {};

  /// One idempotency key per member, kept for retries (E16).
  final Map<String, String> _keys = {};
  late DateTime _date = pakistanToday(ref.read(kametiClockProvider));
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

  Money get _markedTotal =>
      _marked.values.fold(Money.zero, (sum, amount) => sum + amount);

  void _retry() {
    final id = widget.kametiId;
    ref
      ..invalidate(isKametiOwnerProvider(id))
      ..invalidate(kametiMembersProvider(id))
      ..invalidate(memberBalancesProvider(id))
      ..invalidate(memberMonthsProvider(id))
      ..invalidate(monthCollectionsProvider(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.kametiId;
    final owner = ref.watch(isKametiOwnerProvider(id));
    final members = ref.watch(kametiMembersProvider(id));
    final balances = ref.watch(memberBalancesProvider(id));
    final months = ref.watch(memberMonthsProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));

    final current = collections.value?.where((c) => c.isCurrent).firstOrNull;
    final isOwner = owner.value ?? false;
    final entries = members.hasValue && balances.hasValue && months.hasValue
        ? settleEntries(
            members.requireValue,
            balances.requireValue,
            months.requireValue,
          )
        : const <SettleEntry>[];

    return KScaffold(
      appBar: KAppBar(
        title: current == null
            ? l10n.settleSaveEmpty
            : l10n.settleTitle(monthName(context, current.monthStart)),
        leading: KAppBarLeading.close,
        actions: [
          if (isOwner && entries.isNotEmpty)
            KButton.secondary(
              label: l10n.settleMarkAll,
              onPressed: _saving ? null : () => _markAll(entries),
            ),
        ],
      ),
      bottomBar: isOwner && entries.isNotEmpty ? _bottomBar(l10n) : null,
      body: PaymentsAsyncGate(
        values: [owner],
        onRetry: _retry,
        builder: (context) => !owner.requireValue
            ? const NotOwnerState()
            : PaymentsAsyncGate(
                values: [members, balances, months, collections],
                onRetry: _retry,
                builder: (context) => current == null
                    ? KEmptyState(title: l10n.settleNotCollecting)
                    : _list(l10n, current, entries),
              ),
      ),
    );
  }

  Widget _list(
    AppLocalizations l10n,
    MonthCollectionRow current,
    List<SettleEntry> entries,
  ) {
    final pot = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpace.gutter,
        KSpace.md,
        KSpace.gutter,
        KSpace.md,
      ),
      child: KPotProgress(
        collected: current.received,
        target: current.target,
        marked: _markedTotal,
        caption: _marked.isEmpty ? null : l10n.settleLighterBar,
      ),
    );
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pot,
          Expanded(child: KEmptyState(title: l10n.settleEveryonePaid)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(bottom: KSpace.lg),
      itemCount: entries.length + 2,
      separatorBuilder: (_, i) =>
          i < 2 ? const SizedBox.shrink() : const KGap.sm(),
      itemBuilder: (context, i) {
        if (i == 0) return pot;
        if (i == 1) {
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpace.gutter,
              0,
              KSpace.gutter,
              KSpace.sm,
            ),
            child: KSectionHeader(title: l10n.settleInstructions),
          );
        }
        final e = entries[i - 2];
        final marked = _marked[e.member.id];
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: KSpace.gutter,
          ),
          child: KSettleRow(
            key: ValueKey(e.member.id),
            name: e.member.name,
            colorIndex: e.colorIndex,
            owed: e.owed,
            marked: marked,
            onMarkFull: _saving ? null : () => _mark(e.member.id, e.owed),
            onUndo: _saving ? null : () => _unmark(e.member.id),
            onEdit: _saving ? null : () => _edit(l10n, e),
          ),
        );
      },
    );
  }

  Widget _bottomBar(AppLocalizations l10n) {
    final count = _marked.length;
    final total = _markedTotal;
    return PaymentsBottomBar(
      children: [
        KDatePicker(
          value: _date,
          lastDate: pakistanToday(ref.read(kametiClockProvider)),
          onChanged: _saving ? null : (d) => setState(() => _date = d),
        ),
        PaymentMethodControl(
          value: _method,
          onChanged: _saving ? null : (m) => setState(() => _method = m),
        ),
        KButton.primary(
          label: count == 0
              ? l10n.settleSaveEmpty
              : l10n.settleSave(count, total.format()),
          expand: true,
          isLoading: _saving,
          onPressed: count == 0 ? null : _save,
        ),
      ],
    );
  }

  void _mark(String memberId, Money amount) => setState(() {
    _marked[memberId] = amount;
  });

  void _unmark(String memberId) => setState(() => _marked.remove(memberId));

  void _markAll(List<SettleEntry> entries) => setState(() {
    for (final e in entries) {
      _marked[e.member.id] = e.owed;
    }
  });

  Future<void> _edit(AppLocalizations l10n, SettleEntry e) async {
    final amount = await showAmountSheet(
      context,
      title: l10n.settleEditTitle(e.member.name),
      initial: _marked[e.member.id] ?? e.owed,
      suggestions: [
        KAmountSuggestion(
          e.owed,
          label: l10n.payRemainingChip(e.owed.format(symbol: false)),
        ),
      ],
    );
    if (amount != null && mounted) _mark(e.member.id, amount);
  }

  Future<void> _save() async {
    if (_saving || _marked.isEmpty) return; // E16: ignore repeat taps.
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final items = [
      for (final MapEntry(key: memberId, value: amount) in _marked.entries)
        BatchPaymentItem(
          memberId: memberId,
          amount: amount,
          idempotencyKey: _keys.putIfAbsent(memberId, newIdempotencyKey),
        ),
    ];
    final result = await ref
        .read(paymentsActionsProvider.notifier)
        .recordBatch(
          kametiId: widget.kametiId,
          receivedOn: _date,
          method: _method,
          items: items,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showToast(
          l10n.settleSaved(items.length),
          tone: KToastTone.positive,
        );
        await Navigator.of(context).maybePop();
      case Err(:final failure):
        setState(() => _saving = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }
}
