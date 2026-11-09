import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Pay out a month's pot (board AF-Record-Payout, FR-51–FR-53).
/// Placeholder: the payments screen session replaces this.
class RecordPayoutScreen extends StatelessWidget {
  const new({required this.kametiId, required this.month, super.key});

  final String kametiId;
  final int month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KScaffold(
      appBar: KAppBar(title: l10n.appTitle),
      body: KEmptyState(title: l10n.comingSoon),
    );
  }
}
