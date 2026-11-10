import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
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
///
/// With a [draftId] it reopens that draft (loaded from the server) instead
/// of starting a new kameti.
class CreateKametiScreen extends ConsumerStatefulWidget {
  const new({this.draftId, super.key});

  final String? draftId;

  @override
  ConsumerState<CreateKametiScreen> createState() => _CreateKametiScreenState();
}

class _CreateKametiScreenState extends ConsumerState<CreateKametiScreen> {
  late bool _loading = widget.draftId != null;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    if (_loading) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final failure = await ref
        .read(createWizardProvider.notifier)
        .resume(widget.draftId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_failure != null || _loading) {
      return KScaffold(
        appBar: KAppBar(title: l10n.createTitle, leading: KAppBarLeading.close),
        body: Padding(
          padding: const EdgeInsetsDirectional.all(KSpace.gutter),
          child: _failure == null
              ? const KSkeletonList()
              : KErrorState(
                  message: failureMessage(l10n, _failure!),
                  onRetry: _load,
                ),
        ),
      );
    }
    return const _CreateWizardView();
  }
}

class _CreateWizardView extends ConsumerWidget {
  const new();

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
