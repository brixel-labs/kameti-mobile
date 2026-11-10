import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

const _quickDueDays = [5, 10, 15];

/// Last day a kameti can be due (every month has it).
const _lastDueDay = 28;

/// Step 2 (AC-2): due day, reminder days and the slots-per-person limit.
class DatesStep extends ConsumerWidget {
  const new({super.key});

  Future<void> _pickOtherDay(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(createWizardProvider).dueDay;
    final day = await showKSheet<int>(
      context,
      title: l10n.createPickDueDay,
      builder: (sheet) => _DayGrid(
        days: [for (var d = 1; d <= _lastDueDay; d++) d],
        isSelected: (d) => d == current,
        semanticLabel: (d) => dayOrdinal(l10n, d),
        onTap: (d) => Navigator.of(sheet).pop(d),
      ),
    );
    if (day != null) ref.read(createWizardProvider.notifier).setDueDay(day);
  }

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    final failure = await ref.read(createWizardProvider.notifier).saveDates();
    if (failure != null && context.mounted) {
      context.showToast(
        failureMessage(AppLocalizations.of(context), failure),
        tone: KToastTone.negative,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final s = ref.watch(createWizardProvider);
    final controller = ref.read(createWizardProvider.notifier);
    final isOther = !_quickDueDays.contains(s.dueDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              WizardHeading(
                title: l10n.createDatesTitle,
                subtitle: l10n.createDatesSubtitle,
              ),
              const KGap.lg(),
              WizardLabel(l10n.createPayBy),
              Wrap(
                spacing: KSpace.sm,
                runSpacing: KSpace.sm,
                children: [
                  for (final day in _quickDueDays)
                    KAmountChip(
                      label: dayOrdinal(l10n, day),
                      selected: s.dueDay == day,
                      onTap: () => controller.setDueDay(day),
                    ),
                  KAmountChip(
                    label: isOther
                        ? dayOrdinal(l10n, s.dueDay)
                        : l10n.createDueOther,
                    selected: isOther,
                    onTap: () => _pickOtherDay(context, ref),
                  ),
                ],
              ),
              const KGap.lg(),
              WizardLabel(l10n.createRemindOn),
              _DayGrid(
                days: [for (var d = 1; d <= s.dueDay; d++) d],
                isSelected: s.reminderDays.contains,
                semanticLabel: l10n.createReminderDay,
                onTap: controller.toggleReminderDay,
              ),
              const KGap.sm(),
              Text(
                l10n.createRemindAt,
                style: k.text.bodySm.copyWith(color: k.colors.textSecondary),
              ),
              const KGap.lg(),
              KCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.createMaxSlotsTitle, style: k.text.body),
                          Text(
                            l10n.createMaxSlotsSubtitle(maxSlotsLimit),
                            style: k.text.caption.copyWith(
                              color: k.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    WizardStepper(
                      framed: false,
                      value: s.maxSlotsPerMember,
                      decreaseLabel: l10n.createFewerSlots,
                      increaseLabel: l10n.createMoreSlots,
                      onDecrease: s.maxSlotsPerMember > 1
                          ? () => controller.setMaxSlotsPerMember(
                              s.maxSlotsPerMember - 1,
                            )
                          : null,
                      onIncrease: s.maxSlotsPerMember < maxSlotsLimit
                          ? () => controller.setMaxSlotsPerMember(
                              s.maxSlotsPerMember + 1,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        WizardFooter(
          backLabel: l10n.dsBack,
          onBack: controller.back,
          primaryLabel: l10n.createNextMembers,
          onPrimary: () => _next(context, ref),
          isLoading: s.busy,
        ),
      ],
    );
  }
}

/// A 5-column grid of day toggles (reminder days, the "Other" due day).
class _DayGrid extends StatelessWidget {
  const new({
    required this.days,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  static const _columns = 5;

  final List<int> days;
  final bool Function(int day) isSelected;
  final String Function(int day) semanticLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < days.length; start += _columns) {
      if (start > 0) rows.add(const KGap(KSpace.xs + KSpace.xxs));
      rows.add(
        Row(
          children: [
            for (var i = start; i < start + _columns; i++) ...[
              if (i > start) const KGap(KSpace.xs + KSpace.xxs),
              Expanded(
                child: i < days.length
                    ? _DayCell(
                        day: days[i],
                        selected: isSelected(days[i]),
                        semanticLabel: semanticLabel(days[i]),
                        onTap: () => onTap(days[i]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final radius = BorderRadius.circular(KRadius.md);
    return Semantics(
      button: true,
      toggled: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.brand : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? c.brand : c.borderStrong),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KSize.minTouch),
            child: Center(
              child: Text(
                '$day',
                style: (selected ? k.text.bodyStrong : k.text.body).copyWith(
                  color: selected ? c.textOnBrand : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
