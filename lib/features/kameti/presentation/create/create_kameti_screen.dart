import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Create-kameti wizard, 6 steps (board AC-1…AC-6, FR-10–FR-13).
/// Placeholder: the create-wizard screen session replaces this.
class CreateKametiScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KScaffold(
      appBar: KAppBar(title: l10n.appTitle),
      body: KEmptyState(title: l10n.comingSoon),
    );
  }
}
