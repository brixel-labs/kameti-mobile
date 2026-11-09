import 'package:flutter/widgets.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Record one payment (board A-Record-Payment, FR-40–FR-42).
/// Placeholder: the payments screen session replaces this.
class RecordPaymentScreen extends StatelessWidget {
  const new({required this.kametiId, this.memberId, super.key});

  final String kametiId;
  final String? memberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KScaffold(
      appBar: KAppBar(title: l10n.appTitle),
      body: KEmptyState(title: l10n.comingSoon),
    );
  }
}
