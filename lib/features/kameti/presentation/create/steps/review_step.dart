import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_async.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/features/ledger/domain/plan_validation.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// The FR-12 checks for the review step, from `validatePlanForStart`.
class ReviewChecks {
  new({
    required List<Slot> slots,
    required List<Share> shares,
    required List<Member> members,
    required int months,
    required Money slotAmount,
    required int maxSlotsPerMember,
  }) {
    final plan = planOf(
      months: months,
      slotAmount: slotAmount,
      maxSlotsPerMember: maxSlotsPerMember,
      slots: slots,
      shares: shares,
    );
    issues = validatePlanForStart(plan);
    emptySlots = plan.slots.where((s) => s.shares.isEmpty).length;
    wrongCount = issues.whereType<WrongSlotCount>().isNotEmpty;
    badSums = plan.slots
        .where((s) => s.shares.isNotEmpty)
        .where((s) => validateSlot(s, slotAmount).isNotEmpty)
        .length;
    payoutMonthsOk =
        !wrongCount && issues.whereType<PayoutMonthProblem>().isEmpty;
    overLimit = [
      for (final issue in issues.whereType<TooManySlotsForMember>())
        members.where((m) => m.id == issue.memberId).firstOrNull?.name ?? '',
    ];
    final inASlot = plan.memberIds.toSet();
    notInSlot = [
      for (final m in members)
        if (!inASlot.contains(m.id)) m.name,
    ];
  }

  late final List<PlanIssue> issues;
  late final int emptySlots;
  late final bool wrongCount;
  late final int badSums;
  late final bool payoutMonthsOk;
  late final List<String> overLimit;

  /// A warning only: it doesn't block the start.
  late final List<String> notInSlot;

  bool get canStart => issues.isEmpty;
}

/// Step 6 (AC-6): summary, the FR-12 checks, Save draft and Start.
/// Issues are shown before the server is asked; the server checks again.
class ReviewStep extends ConsumerWidget {
  const new({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    ReviewChecks checks,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!checks.canStart) {
      context.showToast(l10n.createFixChecks, tone: KToastTone.negative);
      return;
    }
    final result = await ref.read(createWizardProvider.notifier).start();
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        context
          ..showToast(l10n.createStarted, tone: KToastTone.positive)
          ..go(Routes.kameti(value));
      case Err(:final failure):
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  void _saveDraft(BuildContext context, WidgetRef ref) {
    ref.read(createWizardProvider.notifier).finishAsDraft();
    context
      ..showToast(AppLocalizations.of(context).createDraftSaved)
      ..go(Routes.home);
  }

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
    final checks = ReviewChecks(
      slots: slots,
      shares: shares,
      members: members,
      months: s.months,
      slotAmount: slotAmount,
      maxSlotsPerMember: s.maxSlotsPerMember,
    );

    final firstSlot = slots.where((x) => x.payoutMonthIndex == 1).firstOrNull;
    final firstNames = firstSlot == null
        ? const <String>[]
        : [
            for (final sh in sharesOfSlot(shares, firstSlot.id))
              members.where((m) => m.id == sh.memberId).firstOrNull?.name ?? '',
          ];
    final range = l10n.createMonthRange(
      monthLabel(context, s.startMonth),
      monthLabel(context, s.endMonth),
    );
    final dueDay = dayOrdinal(l10n, s.dueDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              WizardHeading(title: l10n.createReviewTitle),
              const KGap.md(),
              KCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(s.name, style: k.text.title)),
                        KIconButton(
                          icon: Icons.edit_outlined,
                          semanticLabel: l10n.dsEdit,
                          onPressed: () => controller.goTo(WizardStep.basics),
                          size: KSpace.lg + KSpace.xxs,
                        ),
                      ],
                    ),
                    const KGap.sm(),
                    KKeyValueList(
                      items: [
                        KKeyValue(
                          l10n.createPotEachMonth,
                          amount: slotAmount * s.months,
                          emphasis: true,
                        ),
                        KKeyValue(
                          l10n.createSlotAmountKey,
                          value: l10n.createPerMonth(slotAmount.format()),
                        ),
                        KKeyValue(
                          l10n.createRuns,
                          value: l10n.createRunsMonths(range, s.months),
                        ),
                        KKeyValue(
                          l10n.createMembersKey,
                          value: l10n.createPeopleCount(members.length),
                        ),
                        KKeyValue(
                          l10n.createDueByKey,
                          value: s.reminderDays.isEmpty
                              ? l10n.createNoReminders(dueDay)
                              : l10n.createDueByValue(
                                  dueDay,
                                  s.reminderDays.join(', '),
                                ),
                        ),
                        KKeyValue(
                          l10n.createFirstPayoutKey,
                          value: firstNames.isEmpty
                              ? l10n.createNotSet
                              : l10n.createFirstPayoutValue(
                                  firstNames.join(' + '),
                                  monthLabel(context, s.startMonth),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const KGap.md(),
              KCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KSectionHeader(title: l10n.createChecks),
                    WizardCheckRow(
                      ok: checks.emptySlots == 0 && !checks.wrongCount,
                      label: checks.emptySlots == 0
                          ? l10n.createCheckSlotsFilled(s.months)
                          : l10n.createCheckSlotsEmpty(checks.emptySlots),
                    ),
                    WizardCheckRow(
                      ok: checks.badSums == 0,
                      label: checks.badSums == 0
                          ? l10n.createCheckSlotsAddUp(slotAmount.format())
                          : l10n.createCheckSlotsDontAddUp(
                              checks.badSums,
                              slotAmount.format(),
                            ),
                    ),
                    WizardCheckRow(
                      ok: checks.payoutMonthsOk,
                      label: checks.payoutMonthsOk
                          ? l10n.createCheckPayoutMonths
                          : l10n.createCheckPayoutMonthsBad,
                    ),
                    WizardCheckRow(
                      ok: checks.overLimit.isEmpty,
                      label: checks.overLimit.isEmpty
                          ? l10n.createCheckSlotLimit(s.maxSlotsPerMember)
                          : l10n.createCheckOverLimit(
                              joinNames(l10n, checks.overLimit),
                              checks.overLimit.length,
                              s.maxSlotsPerMember,
                            ),
                    ),
                  ],
                ),
              ),
              if (checks.notInSlot.isNotEmpty) ...[
                const KGap.md(),
                KInfoBanner(
                  tone: KBannerTone.warning,
                  message: l10n.createNotInSlot(
                    checks.notInSlot.length,
                    joinNames(l10n, checks.notInSlot),
                  ),
                ),
              ],
              const KGap.md(),
              Text(
                l10n.createStartNote,
                style: k.text.caption.copyWith(color: k.colors.textSecondary),
              ),
            ],
          ),
        ),
        WizardFooter(
          backLabel: l10n.createSaveDraft,
          onBack: s.busy ? null : () => _saveDraft(context, ref),
          primaryLabel: l10n.createStart,
          onPrimary: () => _start(context, ref, checks),
          isLoading: s.busy,
        ),
      ],
    );
  }
}
