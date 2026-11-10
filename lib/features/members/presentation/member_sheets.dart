import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/ledger/data/ledger_providers.dart';
import 'package:kameti/features/members/data/contacts_providers.dart';
import 'package:kameti/features/members/domain/contact_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Re-reads everything a member change touches.
void _refreshMembers(WidgetRef ref, String kametiId) => ref
  ..invalidate(kametiMembersProvider(kametiId))
  ..invalidate(kametiSharesProvider(kametiId))
  ..invalidate(memberBalancesProvider(kametiId))
  ..invalidate(myContactsProvider);

/// Opens the "Add a member" sheet (FR-20): pick from "My people" or type a
/// new person. Owner only; the backend checks that too.
Future<void> showAddMemberSheet(
  BuildContext context, {
  required String kametiId,
  required List<Member> members,
}) => showKSheet<void>(
  context,
  title: AppLocalizations.of(context).membersAddTitle,
  builder: (_) => AddMemberForm(kametiId: kametiId, members: members),
);

/// Opens the edit sheet for [member], with "Remove member" at the bottom.
Future<void> showEditMemberSheet(
  BuildContext context, {
  required Member member,
}) => showKSheet<void>(
  context,
  title: AppLocalizations.of(context).membersEditTitle,
  builder: (_) => EditMemberForm(member: member),
);

class AddMemberForm extends ConsumerStatefulWidget {
  const new({required this.kametiId, required this.members, super.key});

  final String kametiId;
  final List<Member> members;

  @override
  ConsumerState<AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<AddMemberForm> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  bool get _nameOk => _name.text.trim().isNotEmpty;
  bool get _emailOk =>
      _email.text.trim().isEmpty || _emailPattern.hasMatch(_email.text.trim());

  Future<void> _add({
    required String shownName,
    String? name,
    String? contactId,
    String? email,
    String? phone,
    String? nickname,
  }) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await ref
        .read(kametiRepositoryProvider)
        .addMember(
          widget.kametiId,
          name: name,
          contactId: contactId,
          email: email,
          phone: phone,
          nickname: nickname,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        _refreshMembers(ref, widget.kametiId);
        context.showToast(
          l10n.membersAdded(shownName),
          tone: KToastTone.positive,
        );
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  Future<void> _submitNew() async {
    setState(() => _submitted = true);
    if (!_nameOk || !_emailOk || _busy) return;
    await _add(
      name: _name.text.trim(),
      email: _nullIfEmpty(_email.text),
      phone: _nullIfEmpty(_phone.text),
      nickname: _nullIfEmpty(_nickname.text),
      shownName: _name.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final contacts = ref.watch(myContactsProvider).value ?? const <Contact>[];
    final taken = {
      for (final m in widget.members)
        if (m.contactId != null) m.contactId,
    };
    final available = [
      for (final c in contacts)
        if (!taken.contains(c.id)) c,
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.gutter,
        vertical: KSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (available.isNotEmpty) ...[
            KSectionHeader(title: l10n.membersFromContacts),
            for (final c in available)
              KListTile(
                leading: KAvatar(name: c.name, colorIndex: 0),
                title: c.name,
                subtitle: c.email ?? c.phone,
                trailing: Icon(Icons.add, color: k.colors.brand),
                onTap: _busy
                    ? null
                    : () => _add(contactId: c.id, shownName: c.name),
              ),
            const KGap.md(),
            KSectionHeader(title: l10n.membersOrAddNew),
          ],
          KTextField(
            label: l10n.membersName,
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            error: _submitted && !_nameOk ? l10n.membersNameRequired : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersNickname,
            hint: l10n.membersNicknameHint,
            controller: _nickname,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            error: _submitted && !_emailOk ? l10n.membersEmailInvalid : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersPhone,
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 32,
          ),
          const KGap.lg(),
          KButton.primary(
            label: l10n.membersAdd,
            icon: Icons.person_add_alt,
            expand: true,
            isLoading: _busy,
            onPressed: _submitNew,
          ),
        ],
      ),
    );
  }
}

class EditMemberForm extends ConsumerStatefulWidget {
  const new({required this.member, super.key});

  final Member member;

  @override
  ConsumerState<EditMemberForm> createState() => _EditMemberFormState();
}

class _EditMemberFormState extends ConsumerState<EditMemberForm> {
  late final _name = TextEditingController(text: widget.member.name);
  late final _nickname = TextEditingController(
    text: widget.member.nickname ?? '',
  );
  late final _email = TextEditingController(text: _contact?.email ?? '');
  late final _phone = TextEditingController(text: _contact?.phone ?? '');
  bool _busy = false;
  bool _submitted = false;

  Contact? get _contact {
    final id = widget.member.contactId;
    if (id == null) return null;
    final contacts = ref.read(myContactsProvider).value ?? const <Contact>[];
    return contacts.where((c) => c.id == id).firstOrNull;
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().isNotEmpty;
  bool get _emailOk =>
      _email.text.trim().isEmpty || _emailPattern.hasMatch(_email.text.trim());

  /// The new value when it differs from [original], else null (unchanged).
  /// An emptied field is sent as '' so the backend clears it.
  String? _changed(String text, String? original) {
    final t = text.trim();
    return t == (original ?? '') ? null : t;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!_nameOk || !_emailOk || _busy) return;
    final m = widget.member;
    setState(() => _busy = true);
    final result = await ref
        .read(kametiRepositoryProvider)
        .updateMember(
          m.id,
          name: _changed(_name.text, m.name),
          nickname: _changed(_nickname.text, m.nickname),
          email: _changed(_email.text, _contact?.email),
          phone: _changed(_phone.text, _contact?.phone),
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        _refreshMembers(ref, m.kametiId);
        context.showToast(l10n.membersUpdated, tone: KToastTone.positive);
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final m = widget.member;
    final ok = await showKConfirm(
      context,
      title: l10n.membersRemoveTitle(m.name),
      message: l10n.membersRemoveBody,
      confirmLabel: l10n.membersRemove,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(kametiRepositoryProvider).removeMember(m.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        _refreshMembers(ref, m.kametiId);
        context.showToast(l10n.membersRemoved, tone: KToastTone.positive);
        Navigator.of(context).pop();
      case Err(:final failure):
        // e.g. member_has_history once the kameti has started.
        setState(() => _busy = false);
        context.showToast(
          failureMessage(l10n, failure),
          tone: KToastTone.negative,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: KSpace.gutter,
        vertical: KSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KTextField(
            label: l10n.membersName,
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            error: _submitted && !_nameOk ? l10n.membersNameRequired : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersNickname,
            hint: l10n.membersNicknameHint,
            controller: _nickname,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            error: _submitted && !_emailOk ? l10n.membersEmailInvalid : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.membersPhone,
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 32,
          ),
          const KGap.lg(),
          KButton.primary(
            label: l10n.membersSave,
            expand: true,
            isLoading: _busy,
            onPressed: _save,
          ),
          const KGap.sm(),
          KButton.destructive(
            label: l10n.membersRemove,
            icon: Icons.person_remove_outlined,
            expand: true,
            onPressed: _busy ? null : _remove,
          ),
        ],
      ),
    );
  }
}
