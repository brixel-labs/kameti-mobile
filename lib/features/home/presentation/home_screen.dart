import 'package:flutter/material.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Home, first-time empty state (board: AF-Empty-Home).
class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(KSpace.gutter),
          children: [
            Text(l10n.appTitle, style: k.text.titleLg),
            const KGap.lg(),
            KCard(
              child: Column(
                children: [
                  Icon(
                    Icons.donut_large_outlined,
                    size: 56,
                    color: k.colors.brand,
                  ),
                  const KGap.md(),
                  Text(l10n.homeEmptyTitle, style: k.text.title),
                  const KGap.sm(),
                  Text(
                    l10n.homeEmptyBody,
                    textAlign: TextAlign.center,
                    style: k.text.bodySm.copyWith(
                      color: k.colors.textSecondary,
                    ),
                  ),
                  const KGap.lg(),
                  KButton.primary(
                    label: l10n.startKameti,
                    icon: Icons.add,
                    expand: true,
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
