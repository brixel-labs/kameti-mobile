import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// One kameti: owner tabs (Overview, Members, Schedule, Payments, Notes)
/// or the member read-only view (board A-Overview, A2-*-Tab,
/// A-Member-View).
/// Placeholder: the kameti-detail screen session replaces this.
class KametiDetailScreen extends StatelessWidget {
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
