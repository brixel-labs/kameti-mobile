import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/payments_controller.dart';
import 'package:kameti/features/payments/presentation/payout_plan.dart';
import 'package:kameti/features/payments/presentation/widgets/payments_widgets.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Pay out a month's pot (board AF-Record-Payout, FR-51–FR-53, E20–E23).
class RecordPayoutScreen extends ConsumerStatefulWidget {
  const new({required this.kametiId, required this.month, super.key});

  final String kametiId;

  /// 1-based month index.
  final int month;

  @override
  ConsumerState<RecordPayoutScreen> createState() => _RecordPayoutScreenState();
}

class _RecordPayoutScreenState extends ConsumerState<RecordPayoutScreen> {
  /// Amount per recipient member id; filled from the plan on first build.
  final Map<String, Money?> _amounts = {};

  /// E23 deductions per member id (dues taken from the payout).
  final Map<String, Money> _deductions = {};

  /// Idempotency keys per member, created once and reused on retry (E16).
  final Map<String, String> _payoutKeys = {};
  final Map<String, String> _deductionKeys = {};

  final _note = TextEditingController();
  late DateTime _date = pakistanToday(ref.read(kametiClockProvider));
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  bool _showNoteError = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _retry() {
    final id = widget.kametiId;
    ref
      ..invalidate(isKametiOwnerProvider(id))
      ..invalidate(kametiProvider(id))
      ..invalidate(kametiMembersProvider(id))
      ..invalidate(kametiSlotsProvider(id))
      ..invalidate(kametiSharesProvider(id))
      ..invalidate(kametiPayoutsProvider(id))
      ..invalidate(memberBalancesProvider(id))
      ..invalidate(monthCollectionsProvider(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.kametiId;
    final owner = ref.watch(isKametiOwnerProvider(id));
    final kameti = ref.watch(kametiProvider(id));
    final members = ref.watch(kametiMembersProvider(id));
    final slots = ref.watch(kametiSlotsProvider(id));
    final shares = ref.watch(kametiSharesProvider(id));
    final payouts = ref.watch(kametiPayoutsProvider(id));
    final balances = ref.watch(memberBalancesProvider(id));
    final collections = ref.watch(monthCollectionsProvider(id));
    final data = [
      kameti,
      members,
      slots,
      shares,
      payouts,
      balances,
      collections,
    ];

    final ready = (owner.value ?? false) && data.every((v) => v.hasValue);
    final row = collections.value
        ?.where((c) => c.monthIndex == widget.month)
        .firstOrNull;
    final recipients = ready
        ? payoutRecipients(
            kameti: kameti.requireValue,
            month: widget.month,
            members: members.requireValue,
            slots: slots.requireValue,
            shares: shares.requireValue,
            payouts: payouts.requireValue,
            balances: balances.requireValue,
            shortfall: row?.payoutShortfall ?? Money.zero,
          )
        : const <PayoutRecipient>[];
    for (final r in recipients) {
      _amounts.putIfAbsent(r.member.id, () => r.suggested);
    }

    return KScaffold(
      appBar: KAppBar(
        title: row == null
            ? l10n.payoutSaveEmpty
            : l10n.payoutTitle(monthName(context, row.monthStart)),
        subtitle: kameti.value == null
            ? null
            : l10n.payoutSubtitle(kameti.requireValue.name, widget.month),
        leading: KAppBarLeading.close,
      ),
      bottomBar: ready && row != null && recipients.isNotEmpty
          ? PaymentsBottomBar(children: [_saveButton(l10n, row, recipients)])
          : null,
      body: PaymentsAsyncGate(
        values: [owner],
        onRetry: _retry,
        builder: (context) => !owner.requireValue
            ? const NotOwnerState()
            : PaymentsAsyncGate(
                values: data,
                onRetry: _retry,
                builder: (context) {
                  if (row == null) {
                    return KEmptyState(title: l10n.payoutMonthMissing);
                  }
                  if (recipients.isEmpty) {
                    return KEmptyState(title: l10n.payoutNoRecipients);
                  }
                  return _form(l10n, row, recipients);
                },
              ),
      ),
    );
  }

  Money _total(List<PayoutRecipient> recipients) => recipients.fold(
    Money.zero,
    (sum, r) => sum + (_amounts[r.member.id] ?? Money.zero),
  );

  /// E22: a payout (plus any deduction) that differs from what is still
  /// expected needs a note. A shortfall split counts as different (FR-52:
  /// the note says who covered the gap).
  bool _noteRequired(List<PayoutRecipient> recipients) => recipients.any((r) {
    final amount = _amounts[r.member.id] ?? Money.zero;
    final deduction = _deductions[r.member.id] ?? Money.zero;
    return amount + deduction != r.outstanding;
  });

  Widget _form(
    AppLocalizations l10n,
    MonthCollectionRow row,
    List<PayoutRecipient> recipients,
  ) {
    final short = row.payoutShortfall;
    final noteRequired = _noteRequired(recipients);
    final noteMissing = noteRequired && _note.text.trim().isEmpty;
    return ListView(
      padding: const EdgeInsetsDirectional.all(KSpace.gutter),
      children: [
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KSpace.sm,
            children: [
              KKeyValueList(
                items: [
                  KKeyValue(
                    l10n.payoutCollected,
                    amount: row.received,
                    emphasis: true,
                  ),
                  KKeyValue(l10n.payoutFullPot, amount: row.target),
                ],
              ),
              KPotProgress(
                collected: row.received,
                target: row.target,
                showLabels: false,
              ),
            ],
          ),
        ),
        if (short.isPositive) ...[
          const KGap.md(),
          KInfoBanner(
            tone: KBannerTone.warning,
            message: l10n.payoutShort(short.format()),
          ),
        ],
        const KGap.lg(),
        for (final r in recipients) ...[
          _recipientCard(l10n, r),
          const KGap.md(),
        ],
        if (short.isPositive) ...[
          Text(
            l10n.payoutSplitHint,
            style: context.k.text.caption.copyWith(
              color: context.k.colors.textSecondary,
            ),
          ),
          const KGap.lg(),
        ],
        KDatePicker(
          label: l10n.payoutPaidOn,
          value: _date,
          lastDate: pakistanToday(ref.read(kametiClockProvider)),
          onChanged: _saving ? null : (d) => setState(() => _date = d),
        ),
        const KGap.lg(),
        FieldLabel(l10n.payMethod),
        const KGap.xs(),
        PaymentMethodControl(
          value: _method,
          onChanged: _saving ? null : (m) => setState(() => _method = m),
        ),
        const KGap.lg(),
        KTextField(
          label: l10n.payoutNote,
          controller: _note,
          enabled: !_saving,
          maxLength: 500,
          helper: noteRequired ? l10n.payoutNoteHelper : null,
          error: _showNoteError && noteMissing
              ? l10n.errPayoutNoteRequired
              : null,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _recipientCard(AppLocalizations l10n, PayoutRecipient r) {
    final id = r.member.id;
    final deduction = _deductions[id];
    final amount = _amounts[id];
    final firstName = r.member.name.split(' ').first;
    return KCard(
      padding: const EdgeInsetsDirectional.all(KSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KSpace.sm,
        children: [
          KListTile(
            padding: EdgeInsetsDirectional.zero,
            leading: KAvatar(name: r.member.name, colorIndex: r.colorIndex),
            title: r.member.name,
            subtitle: [
              l10n.payoutRecipientShare(
                r.monthlyShare.format(),
                r.expected.format(),
              ),
              if (r.alreadyPaid.isPositive)
                l10n.payoutAlreadyPaid(r.alreadyPaid.format()),
            ].join('\n'),
          ),
          KAmountField(
            label: l10n.payoutAmountFor(firstName),
            semanticLabel: l10n.payoutAmountFor(r.member.name),
            value: amount,
            step: const Money(1),
            emphasized: false,
            enabled: !_saving,
            onChanged: (v) => setState(() => _amounts[id] = v),
            suggestions: [
              if (r.suggested != amount) KAmountSuggestion(r.suggested),
            ],
          ),
          if (r.owes.isPositive)
            KCheckboxTile(
              title: l10n.payoutDeduct(firstName, r.owes.format()),
              subtitle: deduction == null
                  ? null
                  : l10n.payoutDeductHelper(deduction.format()),
              value: deduction != null,
              onChanged: _saving ? null : (on) => _toggleDeduction(r, on),
            ),
        ],
      ),
    );
  }

  /// E23: taking dues from the payout records a payment for them and
  /// lowers the payout by the same amount.
  void _toggleDeduction(PayoutRecipient r, bool on) {
    final id = r.member.id;
    final amount = _amounts[id] ?? Money.zero;
    setState(() {
      if (on) {
        final take = r.owes < amount ? r.owes : amount;
        if (!take.isPositive) return;
        _deductions[id] = take;
        _amounts[id] = amount - take;
      } else {
        final take = _deductions.remove(id) ?? Money.zero;
        _amounts[id] = amount + take;
      }
    });
  }

  Widget _saveButton(
    AppLocalizations l10n,
    MonthCollectionRow row,
    List<PayoutRecipient> recipients,
  ) {
    final total = _total(recipients);
    final anyMissing = recipients.any((r) => _amounts[r.member.id] == null);
    final anything = total.isPositive || _deductions.isNotEmpty;
    return KButton.primary(
      label: total.isPositive
          ? l10n.payoutSave(total.format())
          : l10n.payoutSaveEmpty,
      expand: true,
      isLoading: _saving,
      onPressed: anyMissing || !anything
          ? null
          : () => _save(l10n, row, recipients),
    );
  }

  Future<void> _save(
    AppLocalizations l10n,
    MonthCollectionRow row,
    List<PayoutRecipient> recipients,
  ) async {
    if (_saving) return; // E16: ignore repeat taps.
    final note = _note.text.trim();
    if (_noteRequired(recipients) && note.isEmpty) {
      setState(() => _showNoteError = true);
      return;
    }
    final total = _total(recipients);
    if (row.payoutShortfall.isPositive) {
      final ok = await showKConfirm(
        context,
        title: l10n.payoutConfirmTitle,
        message: l10n.payoutConfirmBody(
          row.payoutShortfall.format(),
          total.format(),
        ),
        confirmLabel: l10n.payoutConfirm,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _saving = true);
    final lines = [
      for (final r in recipients)
        PayoutLine(
          slotId: r.slotId,
          memberId: r.member.id,
          amount: _amounts[r.member.id] ?? Money.zero,
          idempotencyKey: _payoutKeys.putIfAbsent(
            r.member.id,
            newIdempotencyKey,
          ),
          deduction: switch (_deductions[r.member.id]) {
            final d? => PayoutDeduction(
              amount: d,
              idempotencyKey: _deductionKeys.putIfAbsent(
                r.member.id,
                newIdempotencyKey,
              ),
            ),
            null => null,
          },
        ),
    ];
    final result = await ref
        .read(paymentsActionsProvider.notifier)
        .recordPayouts(
          kametiId: widget.kametiId,
          paidOn: _date,
          method: _method,
          lines: lines,
          note: note.isEmpty ? null : note,
          deductionNote: l10n.payoutDeductNote(widget.month),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showToast(l10n.payoutDone, tone: KToastTone.positive);
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
