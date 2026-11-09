import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/steps/basics_step.dart';
import 'package:kameti/features/kameti/presentation/create/steps/dates_step.dart';
import 'package:kameti/features/kameti/presentation/create/steps/members_step.dart';
import 'package:kameti/features/kameti/presentation/create/steps/order_step.dart';
import 'package:kameti/features/kameti/presentation/create/steps/review_step.dart';
import 'package:kameti/features/kameti/presentation/create/steps/slots_step.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Create-kameti wizard, 6 steps (board AC-1…AC-6, FR-10–FR-12).
/// Owner-only: whoever creates the kameti owns it.
class CreateKametiScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (step, editing) = ref.watch(
      createWizardProvider.select((s) => (s.step, s.editingSlotId)),
    );
    final controller = ref.read(createWizardProvider.notifier);
    final atStart = step == WizardStep.basics && editing == null;

    void close() {
      controller.finishAsDraft();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.home);
      }
    }

    return PopScope(
      canPop: atStart,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: KScaffold(
        appBar: KAppBar(
          title: l10n.createTitle,
          leading: atStart ? KAppBarLeading.close : KAppBarLeading.back,
          onLeading: atStart ? close : controller.back,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                KSpace.gutter,
                KSpace.sm,
                KSpace.gutter,
                0,
              ),
              child: KWizardProgress(step: step.index + 1, showLabel: true),
            ),
            Expanded(
              child: switch (step) {
                WizardStep.basics => const BasicsStep(),
                WizardStep.dates => const DatesStep(),
                WizardStep.members => const MembersStep(),
                WizardStep.slots => const SlotsStep(),
                WizardStep.order => const OrderStep(),
                WizardStep.review => const ReviewStep(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
