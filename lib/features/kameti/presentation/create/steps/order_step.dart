import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_async.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/features/kameti/presentation/create/wizard_format.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Step 5 (AC-5, FR-32): drag to reorder who gets the pot when, or use
/// Random draw / Same as slots. Saved with `reorderSlots` on Next. In a
/// draft nothing is paid out yet, so no month is locked and no confirm is
/// needed.
class OrderStep extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<OrderStep> createState() => _OrderStepState();
}

class _OrderStepState extends ConsumerState<OrderStep> {
  /// Slot ids in the order last saved, and the order being edited.
  List<String>? _saved;
  late List<String> _order;

  Future<void> _next() async {
    final failure = await ref
        .read(createWizardProvider.notifier)
        .saveOrder(original: _saved!, ordered: _order);
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
    final shares = sharesAsync.requireValue;
    final slotsById = {for (final x in slotsAsync.requireValue) x.id: x};
    final savedOrder =
        (slotsAsync.requireValue.toList()..sort(
              (a, b) => a.payoutMonthIndex.compareTo(b.payoutMonthIndex),
            ))
            .map((x) => x.id)
            .toList();
    if (_saved == null || _saved!.length != savedOrder.length) {
      _saved = savedOrder;
      _order = [...savedOrder];
    }
    final order = _order;

    String namesOf(Slot slot) {
      final names = [
        for (final sh in sharesOfSlot(shares, slot.id))
          if (sh.memberId == s.selfMemberId)
            l10n.createYou
          else
            members.where((m) => m.id == sh.memberId).firstOrNull?.name ?? '',
      ];
      return names.isEmpty ? l10n.createEmptySlot : names.join(' + ');
    }

    bool hasSelf(Slot slot) =>
        s.selfMemberId != null &&
        sharesOfSlot(shares, slot.id).any((x) => x.memberId == s.selfMemberId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(KSpace.gutter),
            buildDefaultDragHandles: false,
            header: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: KSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WizardHeading(
                    title: l10n.createOrderTitle,
                    subtitle: l10n.createOrderSubtitle,
                  ),
                  const KGap.lg(),
                  Row(
                    children: [
                      Expanded(
                        child: KButton.secondary(
                          label: l10n.createRandomDraw,
                          icon: Icons.shuffle,
                          expand: true,
                          onPressed: () =>
                              setState(() => order.shuffle(Random())),
                        ),
                      ),
                      const KGap.sm(),
                      Expanded(
                        child: KButton.secondary(
                          label: l10n.createSameAsSlots,
                          expand: true,
                          onPressed: () =>
                              setState(() => _order = [..._saved!]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            itemCount: order.length,
            onReorderItem: (from, to) => setState(() {
              final moved = order.removeAt(from);
              order.insert(to, moved);
            }),
            itemBuilder: (context, index) {
              final slot = slotsById[order[index]]!;
              final month = monthAt(s.startMonth, index + 1);
              return Padding(
                key: ValueKey(slot.id),
                padding: const EdgeInsetsDirectional.only(
                  bottom: KSpace.xs + KSpace.xxs,
                ),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: _OrderRow(
                    index: index,
                    month: month,
                    names: namesOf(slot),
                    highlighted: hasSelf(slot),
                    dragLabel: l10n.createDragToMove(
                      monthLabel(context, month, long: true),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        WizardFooter(
          backLabel: l10n.dsBack,
          onBack: controller.back,
          primaryLabel: l10n.createNextReview,
          onPrimary: _next,
          isLoading: s.busy,
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const new({
    required this.index,
    required this.month,
    required this.names,
    required this.highlighted,
    required this.dragLabel,
  });

  final int index;
  final DateTime month;
  final String names;
  final bool highlighted;
  final String dragLabel;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = k.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpace.md,
        KSpace.xs,
        KSpace.xs,
        KSpace.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted ? c.yourTurn : c.surface,
        borderRadius: BorderRadius.circular(KRadius.input),
        border: Border.all(color: highlighted ? c.yourTurnBorder : c.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: KSize.minTouch,
            child: Semantics(
              label: monthLabel(context, month, long: true),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMM(locale).format(month).toUpperCase(),
                    style: k.text.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlighted ? c.onYourTurn : c.textSecondary,
                    ),
                  ),
                  Text(
                    DateFormat.y(locale).format(month),
                    style: k.text.bodyStrong,
                  ),
                ],
              ),
            ),
          ),
          const KGap.md(),
          Expanded(child: Text(names, style: k.text.body)),
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: dragLabel,
              button: true,
              child: SizedBox.square(
                dimension: KSize.minTouch,
                child: Icon(Icons.drag_indicator, color: c.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
