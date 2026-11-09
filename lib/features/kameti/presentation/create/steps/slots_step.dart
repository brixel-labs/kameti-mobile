import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/steps/slot_split_view.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_async.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/features/ledger/domain/plan_validation.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Step 4 (AC-4): every slot with its sharers and whether it adds up.
/// Tapping a slot opens the split editor (A2-Shares-Amounts).
class SlotsStep extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final s = ref.watch(createWizardProvider);
    final controller = ref.read(createWizardProvider.notifier);
    final id = s.kametiId!;
    final membersAsync = ref.watch(kametiMembersProvider(id));
    final slotsAsync = ref.watch(kametiSlotsProvider(id));
    final sharesAsync = ref.watch(kametiSharesProvider(id));
    final gate = wizardAsyncGate(
      context,
      [membersAsync, slotsAsync, sharesAsync],
      onRetry: () => ref
        ..invalidate(kametiMembersProvider(id))
        ..invalidate(kametiSlotsProvider(id))
        ..invalidate(kametiSharesProvider(id)),
    );
    if (gate != null) return gate;

    final members = membersAsync.requireValue;
    final slots = [...slotsAsync.requireValue]
      ..sort((a, b) => a.payoutMonthIndex.compareTo(b.payoutMonthIndex));
    final shares = sharesAsync.requireValue;
    final slotAmount = s.slotAmount!;

    final editing = s.editingSlotId;
    if (editing != null) {
      final slot = slots.where((x) => x.id == editing).firstOrNull;
      if (slot != null) {
        return SlotSplitView(
          key: ValueKey(slot.id),
          slot: slot,
          members: members,
          shares: shares,
        );
      }
    }

    final ready = slots
        .where((slot) => _isReady(slot, shares, slotAmount))
        .length;
    final inASlot = {for (final sh in shares) sh.memberId};
    final unassigned = [
      for (final m in members)
        if (!inASlot.contains(m.id)) m.name,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              WizardHeading(
                title: l10n.createSlotsTitle(s.months),
                subtitle: l10n.createSlotsSubtitle(slotAmount.format()),
              ),
              const KGap.lg(),
              MergeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.createSlotsReady,
                        style: k.text.bodySm.copyWith(
                          color: k.colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      l10n.createReadyCount(ready, slots.length),
                      style: k.text.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const KGap.xs(),
              WizardProgressBar(done: ready, total: slots.length),
              if (unassigned.isNotEmpty) ...[
                const KGap.md(),
                KInfoBanner(
                  tone: KBannerTone.warning,
                  message: l10n.createNotInSlot(
                    unassigned.length,
                    joinNames(l10n, unassigned),
                  ),
                ),
              ],
              const KGap.md(),
              for (final slot in slots) ...[
                _SlotCard(
                  slot: slot,
                  shares: sharesOfSlot(shares, slot.id),
                  members: members,
                  slotAmount: slotAmount,
                  onTap: () => controller.editSlot(slot.id),
                  month: monthLabel(
                    context,
                    monthAt(s.startMonth, slot.payoutMonthIndex),
                    long: true,
                  ),
                ),
                const KGap.sm(),
              ],
            ],
          ),
        ),
        WizardFooter(
          backLabel: l10n.dsBack,
          onBack: controller.back,
          primaryLabel: l10n.createNextOrder,
          onPrimary: () => controller.goTo(WizardStep.order),
        ),
      ],
    );
  }

  static bool _isReady(Slot slot, List<Share> shares, Money slotAmount) {
    final own = sharesOfSlot(shares, slot.id);
    if (own.isEmpty) return false;
    final plan = planOf(
      months: 1,
      slotAmount: slotAmount,
      maxSlotsPerMember: maxSlotsLimit,
      slots: [slot],
      shares: own,
    );
    return validateSlot(plan.slots.single, slotAmount).isEmpty;
  }
}

class _SlotCard extends StatelessWidget {
  const new({
    required this.slot,
    required this.shares,
    required this.members,
    required this.slotAmount,
    required this.onTap,
    required this.month,
  });

  final Slot slot;
  final List<Share> shares;
  final List<Member> members;
  final Money slotAmount;
  final VoidCallback onTap;
  final String month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final c = k.colors;
    final names = [
      for (final sh in shares)
        members.where((m) => m.id == sh.memberId).firstOrNull?.name ?? '',
    ];
    final total = shares.fold(Money.zero, (sum, sh) => sum + sh.monthlyAmount);
    final remaining = slotAmount - total;
    final empty = shares.isEmpty;
    final ready =
        !empty && remaining.isZero && shares.length <= maxSharersPerSlot;

    final String title;
    final String subtitle;
    var subtitleColor = c.textSecondary;
    if (empty) {
      title = l10n.createEmptySlot;
      subtitle = l10n.createTapToAdd;
    } else {
      title = names.join(' + ');
      if (ready) {
        subtitle = shares.length == 1
            ? l10n.createWholeSlot(slotAmount.format())
            : shares
                  .map((sh) => sh.monthlyAmount.format(symbol: false))
                  .join(' + ');
      } else {
        subtitleColor = c.warning;
        subtitle = remaining.isNegative
            ? l10n.dsOverBy(remaining.abs().format())
            : l10n.createStillToAssign(remaining.format());
      }
    }

    final Widget trailing;
    if (ready) {
      trailing = Icon(
        Icons.check,
        color: c.positive,
        semanticLabel: l10n.createSlotReady,
      );
    } else {
      trailing = Icon(
        empty ? Icons.add : Icons.chevron_right,
        color: empty ? c.brand : c.textSecondary,
      );
    }

    return KCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.md,
        vertical: KSpace.sm + KSpace.xxs,
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(
              minWidth: KSpace.xxl - KSpace.xxs,
              minHeight: KSpace.xxl - KSpace.xxs,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ready || empty ? c.surfaceSunken : c.warningSubtle,
              borderRadius: BorderRadius.circular(KRadius.sm),
            ),
            child: Text(
              '${slot.payoutMonthIndex}',
              semanticsLabel: l10n.createSlotHeader(
                slot.payoutMonthIndex,
                month,
              ),
              style: k.text.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                color: ready || empty ? c.textSecondary : c.warning,
              ),
            ),
          ),
          const KGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: k.text.bodyStrong.copyWith(
                    color: empty ? c.textSecondary : c.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: k.text.caption.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          const KGap.sm(),
          trailing,
        ],
      ),
    );
  }
}
