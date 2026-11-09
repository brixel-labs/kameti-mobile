import 'package:flutter/material.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Target of the invite deep link `/kameti/join/:token`.
/// The real accept-invite flow (board: AF-Join-Invite) comes in Phase 3.
class JoinScreen extends StatelessWidget {
  const new({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(KSpace.gutter),
        child: Text(l10n.joinBody, style: k.text.body),
      ),
    );
  }
}
