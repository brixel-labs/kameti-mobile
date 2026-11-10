import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Splits one slot between up to 4 people by amount (A2-Shares-Amounts,
/// FR-31, §3.1). Saves through `setSlotShares`; the server re-checks the
/// sum, the Rs 1,000 steps, the sharer count and the slot limit.
class SlotSplitView extends ConsumerStatefulWidget {
  const new({
    required this.slot,
    required this.members,
    required this.shares,
    super.key,
  });

  final Slot slot;
  final List<Member> members;

  /// Every share in the kameti (for the per-person slot limit).
  final List<Share> shares;

  @override
  ConsumerState<SlotSplitView> createState() => _SlotSplitViewState();
}

class _Row {
  new(this.memberId, this.amount);
  final String memberId;
  Money? amount;
}

class _SlotSplitViewState extends ConsumerState<SlotSplitView> {
  // Unsaved form state for this one slot (local UI state).
  late final List<_Row> _rows = [
    for (final s in sharesOfSlot(widget.shares, widget.slot.id))
      _Row(s.memberId, s.monthlyAmount),
  ];

  int _colorOf(String memberId) =>
      widget.members.indexWhere((m) => m.id == memberId);

  String _nameOf(String memberId) =>
      widget.members.where((m) => m.id == memberId).firstOrNull?.name ?? '';

  /// Slots this member holds outside the one being edited.
  int _otherSlots(String memberId) => {
    for (final s in widget.shares)
      if (s.memberId == memberId &&
          s.effectiveToMonth == null &&
          s.slotId != widget.slot.id)
        s.slotId,
  }.length;

  Future<void> _addSharer() async {
    final l10n = AppLocalizations.of(context);
    final limit = ref.read(createWizardProvider).maxSlotsPerMember;
    final taken = {for (final r in _rows) r.memberId};
    final candidates = [
      for (final m in widget.members)
        if (!taken.contains(m.id)) m,
    ];
    final picked = await showKSheet<String>(
      context,
      title: l10n.createPickPerson,
      builder: (sheet) => candidates.isEmpty
          ? KEmptyState(title: l10n.createNoOneToAdd)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final m in candidates)
                  Builder(
                    builder: (_) {
                      final count = _otherSlots(m.id);
                      final atLimit = count >= limit;
                      return KListTile(
                        leading: KAvatar(
                          name: m.name,
                          colorIndex: _colorOf(m.id),
                        ),
                        title: m.name,
                        subtitle: atLimit
                            ? l10n.createAtSlotLimit(count)
                            : l10n.createInSlots(count),
                        showDivider: true,
                        onTap: atLimit
                            ? null
                            : () => Navigator.of(sheet).pop(m.id),
                      );
                    },
                  ),
              ],
            ),
    );
    if (picked != null && mounted) {
      setState(() => _rows.add(_Row(picked, null)));
    }
  }

  Future<void> _save() async {
    final failure = await ref
        .read(createWizardProvider.notifier)
        .saveSlotShares(widget.slot.id, [
          for (final r in _rows)
            ShareInput(memberId: r.memberId, monthlyAmount: r.amount!),
        ]);
    if (failure != null && mounted) {
      context.showToast(
        failureMessage(AppLocalizations.of(context), failure),
        tone: KToastTone.negative,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final s = ref.watch(createWizardProvider);
    final controller = ref.read(createWizardProvider.notifier);
    final slotAmount = s.slotAmount!;
    final amounts = [for (final r in _rows) r.amount];
    final issue = KShareSplitEditor.issueFor(slotAmount, amounts);
    final assigned = amounts.fold(
      Money.zero,
      (sum, a) => sum + (a ?? Money.zero),
    );
    final left = slotAmount - assigned;
    final month = monthLabel(
      context,
      monthAt(s.startMonth, widget.slot.payoutMonthIndex),
      long: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              Text(
                l10n
                    .createSlotHeader(widget.slot.payoutMonthIndex, month)
                    .toUpperCase(),
                style: k.text.label.copyWith(color: k.colors.brand),
              ),
              const KGap.xs(),
              WizardHeading(
                title: l10n.createSplitTitle,
                subtitle: l10n.createSplitSubtitle(slotAmount.format()),
              ),
              const KGap.lg(),
              KShareSplitEditor(
                slotAmount: slotAmount,
                sharers: [
                  for (final r in _rows)
                    KSharer(
                      id: r.memberId,
                      name: _nameOf(r.memberId),
                      colorIndex: _colorOf(r.memberId),
                      amount: r.amount,
                      subtitle: r.amount == null
                          ? null
                          : l10n.createGets((r.amount! * s.months).format()),
                    ),
                ],
                onChanged: (i, amount) =>
                    setState(() => _rows[i].amount = amount),
                onAddSharer: _addSharer,
                addSharerLabel: l10n.createAddSharer,
                onRemoveSharer: (i) => setState(() => _rows.removeAt(i)),
              ),
            ],
          ),
        ),
        WizardFooter(
          backLabel: l10n.dsBack,
          onBack: () => controller.editSlot(null),
          primaryLabel: issue == KShareSplitIssue.under && left.isPositive
              ? l10n.dsLeftToAssign(left.format())
              : l10n.createSaveSlot,
          onPrimary: issue == null ? _save : null,
          isLoading: s.busy,
        ),
      ],
    );
  }
}
