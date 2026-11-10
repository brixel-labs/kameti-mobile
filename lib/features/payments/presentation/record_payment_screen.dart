import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/ledger/domain/ledger_rows.dart';
import 'package:kameti/features/payments/data/payments_providers.dart';
import 'package:kameti/features/payments/domain/payment_models.dart';
import 'package:kameti/features/payments/presentation/payment_hint.dart';
import 'package:kameti/features/payments/presentation/payments_controller.dart';
import 'package:kameti/features/payments/presentation/widgets/payments_widgets.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Record one payment (board A-Record-Payment, FR-40–FR-42, E16, E17).
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const new({required this.kametiId, this.memberId, super.key});

  final String kametiId;

  /// Preselected member (from `?member=`).
  final String? memberId;

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  /// One key per opening of the form, reused on every retry (E16).
  final String _idempotencyKey = newIdempotencyKey();
  final _note = TextEditingController();

  late String? _memberId = widget.memberId;
  Money? _amount;
  late DateTime _date = pakistanToday(ref.read(kametiClockProvider));
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

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
      ..invalidate(memberBalancesProvider(id))
      ..invalidate(memberMonthsProvider(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.kametiId;
    final owner = ref.watch(isKametiOwnerProvider(id));
    final kameti = ref.watch(kametiProvider(id));
    final members = ref.watch(kametiMembersProvider(id));
    final balances = ref.watch(memberBalancesProvider(id));
    final months = ref.watch(memberMonthsProvider(id));
    // Only for the E16 duplicate warning; never blocks the form.
    ref.watch(kametiPaymentsProvider(id));

    final ready = owner.hasValue && owner.requireValue;
    return KScaffold(
      appBar: KAppBar(title: l10n.payTitle, leading: KAppBarLeading.close),
      bottomBar: ready && members.hasValue && kameti.hasValue
          ? PaymentsBottomBar(children: [_saveButton(l10n)])
          : null,
      body: PaymentsAsyncGate(
        values: [owner],
        onRetry: _retry,
        builder: (context) => !owner.requireValue
            ? const NotOwnerState()
            : PaymentsAsyncGate(
                values: [kameti, members, balances, months],
                onRetry: _retry,
                builder: (context) => _form(
                  context,
                  kameti.requireValue,
                  members.requireValue,
                  balances.requireValue,
                  months.requireValue,
                ),
              ),
      ),
    );
  }

  Widget _saveButton(AppLocalizations l10n) {
    final amount = _amount;
    final canSave =
        _memberId != null &&
        amount != null &&
        amount.isPositive &&
        !KDatePicker.isAfterLast(
          _date,
          pakistanToday(ref.read(kametiClockProvider)),
        );
    return KButton.primary(
      label: amount != null && amount.isPositive
          ? l10n.paySave(amount.format())
          : l10n.paySaveEmpty,
      expand: true,
      isLoading: _saving,
      onPressed: canSave ? _save : null,
    );
  }

  Widget _form(
    BuildContext context,
    Kameti kameti,
    List<Member> members,
    List<MemberBalanceRow> balances,
    List<MemberMonthRow> months,
  ) {
    final l10n = AppLocalizations.of(context);
    if (members.isEmpty) return KEmptyState(title: l10n.payNoMembers);

    final index = members.indexWhere((m) => m.id == _memberId);
    final member = index < 0 ? null : members[index];
    final balance = balances.where((b) => b.memberId == _memberId).firstOrNull;
    final current = months
        .where((m) => m.memberId == _memberId && m.isCurrent)
        .firstOrNull;
    final owes = balance?.owes ?? Money.zero;
    final monthlyDue = balance?.monthlyDue ?? current?.due ?? Money.zero;

    final hint = balance == null
        ? null
        : PaymentHint.of(
            amount: _amount,
            owes: owes,
            leftForKameti: monthlyDue * kameti.monthsN - balance.totalPaid,
          );

    return ListView(
      padding: const EdgeInsetsDirectional.all(KSpace.gutter),
      children: [
        FieldLabel(l10n.payMember),
        const KGap.xs(),
        KCard(
          padding: EdgeInsetsDirectional.zero,
          child: KListTile(
            leading: member == null
                ? null
                : KAvatar(name: member.name, colorIndex: index),
            title: member?.name ?? l10n.payChooseMember,
            subtitle: current == null
                ? null
                : l10n.payMemberSummary(
                    current.due.format(),
                    current.allocated.format(),
                  ),
            trailing: const Icon(Icons.expand_more),
            onTap: _saving ? null : () => _pickMember(members),
          ),
        ),
        const KGap.lg(),
        KAmountField(
          label: l10n.payAmountReceived,
          value: _amount,
          step: const Money(1),
          enabled: !_saving,
          onChanged: (v) => setState(() => _amount = v),
          suggestions: [
            if (owes.isPositive)
              KAmountSuggestion(
                owes,
                label: l10n.payRemainingChip(owes.format(symbol: false)),
              ),
            if (monthlyDue.isPositive && monthlyDue != owes)
              KAmountSuggestion(
                monthlyDue,
                label: l10n.payFullMonthChip(monthlyDue.format(symbol: false)),
              ),
          ],
        ),
        const KGap.lg(),
        KDatePicker(
          label: l10n.payDateReceived,
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
          label: l10n.payNote,
          controller: _note,
          enabled: !_saving,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (hint != null && member != null) ...[
          const KGap.md(),
          _hintBanner(l10n, hint, member, current),
        ],
      ],
    );
  }

  Widget _hintBanner(
    AppLocalizations l10n,
    PaymentHint hint,
    Member member,
    MemberMonthRow? current,
  ) {
    final firstName = member.name.split(' ').first;
    return switch (hint) {
      HintFullyPaid() => KInfoBanner(
        tone: KBannerTone.positive,
        message: l10n.payHintFullyPaid(
          firstName,
          current == null ? '' : monthName(context, current.monthStart),
        ),
      ),
      HintOwing(:final rest) => KInfoBanner(
        tone: KBannerTone.info,
        message: l10n.payHintOwing(rest.format()),
      ),
      HintCredit(:final extra) => KInfoBanner(
        tone: KBannerTone.info,
        message: l10n.payHintCredit(extra.format()),
      ),
      HintOverKameti(:final leftForKameti) => KInfoBanner(
        tone: KBannerTone.warning,
        message: l10n.payHintOverKameti(firstName, leftForKameti.format()),
      ),
    };
  }

  Future<void> _pickMember(List<Member> members) async {
    final picked = await showKSheet<String>(
      context,
      title: AppLocalizations.of(context).payChooseMember,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, m) in members.indexed)
            KListTile(
              leading: KAvatar(name: m.name, colorIndex: i),
              title: m.name,
              showDivider: i < members.length - 1,
              onTap: () => Navigator.of(context).pop(m.id),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _memberId = picked);
  }

  /// E16: the same member, amount and date recorded in the last 2 minutes.
  bool _looksDuplicate() {
    final payments = ref.read(kametiPaymentsProvider(widget.kametiId)).value;
    if (payments == null) return false;
    final clock = ref.read(kametiClockProvider);
    final nowUtc = clock.now().subtract(KametiClock.pakistanOffset);
    return payments.any(
      (p) =>
          !p.isVoided &&
          p.memberId == _memberId &&
          p.amount == _amount &&
          DateUtils.isSameDay(p.receivedOn, _date) &&
          nowUtc.difference(p.createdAt.toUtc()).abs() <
              const Duration(minutes: 2),
    );
  }

  Future<void> _save() async {
    if (_saving) return; // E16: ignore repeat taps.
    final memberId = _memberId;
    final amount = _amount;
    if (memberId == null || amount == null || !amount.isPositive) return;
    final l10n = AppLocalizations.of(context);

    if (_looksDuplicate()) {
      final members = ref.read(kametiMembersProvider(widget.kametiId)).value;
      final name =
          members?.where((m) => m.id == memberId).firstOrNull?.name ?? '';
      final again = await showKConfirm(
        context,
        title: l10n.payDuplicateTitle,
        message: l10n.payDuplicateBody(name, amount.format()),
        confirmLabel: l10n.payDuplicateConfirm,
      );
      if (!again || !mounted) return;
    }

    setState(() => _saving = true);
    final note = _note.text.trim();
    final result = await ref
        .read(paymentsActionsProvider.notifier)
        .recordPayment(
          kametiId: widget.kametiId,
          memberId: memberId,
          amount: amount,
          receivedOn: _date,
          idempotencyKey: _idempotencyKey,
          method: _method,
          note: note.isEmpty ? null : note,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.showToast(l10n.payRecorded, tone: KToastTone.positive);
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
