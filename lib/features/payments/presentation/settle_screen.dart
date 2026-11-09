import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Record many at once: tap to settle (board A2-Bulk-Confirm, FR-43).
/// Placeholder: the payments screen session replaces this.
class SettleScreen extends StatelessWidget {
  const new({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KScaffold(
      appBar: KAppBar(title: l10n.appTitle),
      body: KEmptyState(title: l10n.comingSoon),
    );
  }
}
