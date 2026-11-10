import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Opens the "Edit kameti" sheet. The name, description and due day can
/// change at any time; the structure (months, slot amount, start) can't
/// once the kameti has started (FR-34), so it isn't offered here.
Future<void> showEditKametiSheet(
  BuildContext context, {
  required Kameti kameti,
}) => showKSheet<void>(
  context,
  title: AppLocalizations.of(context).kametiEditTitle,
  builder: (_) => EditKametiForm(kameti: kameti),
);

class EditKametiForm extends ConsumerStatefulWidget {
  const new({required this.kameti, super.key});

  final Kameti kameti;

  @override
  ConsumerState<EditKametiForm> createState() => _EditKametiFormState();
}

class _EditKametiFormState extends ConsumerState<EditKametiForm> {
  late final _name = TextEditingController(text: widget.kameti.name);
  late final _description = TextEditingController(
    text: widget.kameti.description ?? '',
  );
  late final _dueDay = TextEditingController(text: '${widget.kameti.dueDay}');
  bool _busy = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  bool get _nameOk {
    final length = _name.text.trim().length;
    return length >= 3 && length <= 40;
  }

  int? get _day => int.tryParse(_dueDay.text.trim());
  bool get _dayOk => _day != null && _day! >= 1 && _day! <= 28;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!_nameOk || !_dayOk || _busy) return;
    final k = widget.kameti;
    setState(() => _busy = true);
    final description = _description.text.trim();
    final result = await ref
        .read(kametiRepositoryProvider)
        .updateKametiDraft(
          k.id,
          name: _name.text.trim() == k.name ? null : _name.text.trim(),
          description: description == (k.description ?? '')
              ? null
              : description,
          dueDay: _day == k.dueDay ? null : _day,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref
          ..invalidate(kametiProvider(k.id))
          ..invalidate(myKametisProvider);
        context.showToast(l10n.kametiUpdated, tone: KToastTone.positive);
        Navigator.of(context).pop();
      case Err(:final failure):
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
            label: l10n.kametiName,
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            error: _submitted && !_nameOk ? l10n.kametiNameError : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.md(),
          KTextField(
            label: l10n.kametiDescription,
            controller: _description,
            maxLength: 500,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const KGap.md(),
          KTextField(
            label: l10n.kametiDueDay,
            helper: l10n.kametiDueDayHelper,
            controller: _dueDay,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            error: _submitted && !_dayOk ? l10n.kametiDueDayError : null,
            onChanged: (_) => setState(() {}),
          ),
          const KGap.lg(),
          KButton.primary(
            label: l10n.kametiSave,
            expand: true,
            isLoading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
