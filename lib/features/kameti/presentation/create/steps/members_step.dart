import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_controller.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_async.dart';
import 'package:kameti/features/kameti/presentation/create/widgets/wizard_parts.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Step 3 (AC-3): add people by name and optional email, include the
/// owner ("I'm also a member"), and remove people.
class MembersStep extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MembersStep> createState() => _MembersStepState();
}

class _MembersStepState extends ConsumerState<MembersStep> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      _email.text.trim().isEmpty || _emailPattern.hasMatch(_email.text.trim());

  void _showFailure(Failure? failure) {
    if (failure == null || !mounted) return;
    context.showToast(
      failureMessage(AppLocalizations.of(context), failure),
      tone: KToastTone.negative,
    );
  }

  Future<void> _add() async {
    setState(() => _submitted = true);
    if (_name.text.trim().isEmpty || !_emailValid) return;
    final failure = await ref
        .read(createWizardProvider.notifier)
        .addMember(name: _name.text, email: _email.text);
    if (!mounted) return;
    if (failure == null) {
      _name.clear();
      _email.clear();
      setState(() => _submitted = false);
    }
    _showFailure(failure);
  }

  Future<void> _remove(Member member) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showKConfirm(
      context,
      title: l10n.createRemoveMemberTitle(member.name),
      message: l10n.createRemoveMemberBody,
      confirmLabel: l10n.createRemove,
      cancelLabel: l10n.dsCancel,
      destructive: true,
    );
    if (!ok) return;
    _showFailure(
      await ref.read(createWizardProvider.notifier).removeMember(member.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(createWizardProvider);
    final controller = ref.read(createWizardProvider.notifier);
    final id = s.kametiId!;
    final membersAsync = ref.watch(kametiMembersProvider(id));
    final gate = wizardAsyncGate(context, [
      membersAsync,
    ], onRetry: () => ref.invalidate(kametiMembersProvider(id)));
    final members = membersAsync.value ?? const <Member>[];
    final firstName = _name.text.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(KSpace.gutter),
            children: [
              WizardHeading(
                title: l10n.createMembersTitle,
                subtitle: l10n.createMembersSubtitle,
              ),
              const KGap.lg(),
              KCard(
                padding: const EdgeInsetsDirectional.all(KSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WizardLabel(l10n.createNewPerson),
                    KTextField(
                      label: l10n.createPersonName,
                      controller: _name,
                      error: _submitted && _name.text.trim().isEmpty
                          ? l10n.createPersonNameError
                          : null,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const KGap.sm(),
                    KTextField(
                      label: l10n.createPersonEmail,
                      controller: _email,
                      error: _submitted && !_emailValid
                          ? l10n.createEmailInvalid
                          : null,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                    ),
                    const KGap.md(),
                    KButton.primary(
                      label: firstName.isEmpty
                          ? l10n.createAddPersonEmpty
                          : l10n.createAddPerson(firstName),
                      icon: Icons.person_add_alt_1_outlined,
                      onPressed: _add,
                      isLoading: s.busy,
                      expand: true,
                    ),
                  ],
                ),
              ),
              const KGap.md(),
              KCheckboxTile(
                title: l10n.createAlsoMember,
                value: s.selfMemberId != null,
                onChanged: s.busy
                    ? null
                    : (v) async => _showFailure(
                        await controller.setSelfMember(include: v),
                      ),
              ),
              const KGap.sm(),
              if (gate != null)
                gate
              else if (members.isEmpty)
                KEmptyState(
                  icon: Icons.group_add_outlined,
                  title: l10n.createMembersEmpty,
                  message: l10n.createMembersEmptyBody,
                )
              else ...[
                KSectionHeader(title: l10n.createAddedCount(members.length)),
                for (var i = 0; i < members.length; i++)
                  _memberTile(context, members[i], i, s.selfMemberId, s.emails),
              ],
            ],
          ),
        ),
        WizardFooter(
          backLabel: l10n.dsBack,
          onBack: controller.back,
          primaryLabel: l10n.createNextSlots,
          onPrimary: members.isEmpty
              ? null
              : () => controller.goTo(WizardStep.slots),
        ),
      ],
    );
  }

  Widget _memberTile(
    BuildContext context,
    Member member,
    int index,
    String? selfId,
    Map<String, String?> emails,
  ) {
    final l10n = AppLocalizations.of(context);
    final isSelf = member.id == selfId;
    final hasEmailInfo = emails.containsKey(member.id);
    final email = emails[member.id];
    return KListTile(
      leading: KAvatar(name: member.name, colorIndex: index),
      title: isSelf ? l10n.createYouName(member.name) : member.name,
      subtitle: isSelf
          ? l10n.createOwner
          : (hasEmailInfo ? (email ?? l10n.createNoEmail) : null),
      showDivider: true,
      trailing: isSelf
          ? null
          : KIconButton(
              icon: Icons.close,
              semanticLabel: l10n.dsRemovePerson(member.name),
              onPressed: () => _remove(member),
              size: KSpace.lg + KSpace.xxs,
            ),
    );
  }
}
