import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Quick picks for the slot amount (board AC-1).
const _slotSuggestions = [
  KAmountSuggestion(Money(50000)),
  KAmountSuggestion(Money(100000)),
  KAmountSuggestion(Money(200000)),
  KAmountSuggestion(Money(250000)),
  KAmountSuggestion(Money(500000)),
];

/// Step 1 (AC-1): name, slot amount, months, first month and a live
/// "What this means" summary. Next creates or updates the draft.
class BasicsStep extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<BasicsStep> {
  late final _name = TextEditingController(
    text: ref.read(createWizardProvider).name,
  );

  /// Errors show only after the first Next tap.
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final controller = ref.read(createWizardProvider.notifier);
    setState(() => _submitted = true);
    if (!controller.nameValid || !controller.slotAmountValid) return;
    final failure = await controller.saveBasics();
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
    final s = ref.watch(createWizardProvider);
    final controller = ref.read(createWizardProvider.notifier);
    final current = ref.watch(createWizardClockProvider).currentMonth();
    final amount = s.slotAmount ?? Money.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              WizardHeading(
                title: l10n.createBasicsTitle,
                subtitle: l10n.createBasicsSubtitle,
              ),
              const KGap.lg(),
              KTextField(
                label: l10n.createNameLabel,
                helper: l10n.createNameHelper,
                error: _submitted && !controller.nameValid
                    ? l10n.createNameError
                    : null,
                controller: _name,
                maxLength: nameMaxLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: controller.setName,
              ),
              const KGap.lg(),
              KAmountField(
                label: l10n.createSlotAmountLabel,
                value: s.slotAmount,
                onChanged: controller.setSlotAmount,
                min: const Money(1000),
                error: _submitted && s.slotAmount == null
                    ? l10n.createSlotAmountRequired
                    : null,
                suggestions: _slotSuggestions,
              ),
              const KGap.lg(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WizardLabel(l10n.createMonthsLabel),
                        WizardStepper(
                          value: s.months,
                          decreaseLabel: l10n.createFewerMonths,
                          increaseLabel: l10n.createMoreMonths,
                          onDecrease: s.months > minMonths
                              ? () => controller.setMonths(s.months - 1)
                              : null,
                          onIncrease: s.months < maxMonths
                              ? () => controller.setMonths(s.months + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const KGap.md(),
                  Expanded(
                    child: KMonthPicker(
                      label: l10n.createFirstMonthLabel,
                      value: s.startMonth,
                      firstMonth: DateTime.utc(current.year - 1, current.month),
                      lastMonth: DateTime.utc(current.year + 2, current.month),
                      onChanged: controller.setStartMonth,
                    ),
                  ),
                ],
              ),
              const KGap.lg(),
              KCard(
                child: KKeyValueList(
                  title: l10n.createWhatThisMeans,
                  items: [
                    KKeyValue(
                      l10n.createPotEachMonth,
                      amount: amount * s.months,
                      emphasis: true,
                    ),
                    KKeyValue(
                      l10n.createSlotPaysInTotal,
                      amount: amount * s.months,
                    ),
                    KKeyValue(
                      l10n.createRuns,
                      value: l10n.createMonthRange(
                        monthLabel(context, s.startMonth),
                        monthLabel(context, s.endMonth),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        WizardFooter(
          primaryLabel: l10n.createNextDueDate,
          onPrimary: _next,
          isLoading: s.busy,
        ),
      ],
    );
  }
}
