import 'package:flutter/material.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Notes tab (board A2-Notes-Tab). Notes arrive in a later update.
class NotesTab extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.all(KSpace.gutter),
      child: KEmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: l10n.detailNotesTitle,
        message: l10n.detailNotesBody,
      ),
    );
  }
}
