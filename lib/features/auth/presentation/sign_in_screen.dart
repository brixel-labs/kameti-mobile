import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Sign-in screen (board: AF-Sign-In). Google/Apple sign-in arrives in
/// Phase 2; for now both buttons go to Home.
class SignInScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: KSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: k.colors.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.groups_2_outlined,
                    color: k.colors.textOnBrand,
                    size: 36,
                    semanticLabel: l10n.appTitle,
                  ),
                ),
              ),
              const KGap.xl(),
              Text(
                l10n.signInTagline,
                style: k.text.displayLg.copyWith(height: 1.1),
              ),
              const KGap.md(),
              Text(
                l10n.signInBody,
                style: k.text.body.copyWith(color: k.colors.textSecondary),
              ),
              const Spacer(),
              KButton.primary(
                label: l10n.continueWithApple,
                icon: Icons.apple,
                expand: true,
                onPressed: () => context.go(Routes.home),
              ),
              const KGap.sm(),
              KButton.secondary(
                label: l10n.continueWithGoogle,
                expand: true,
                onPressed: () => context.go(Routes.home),
              ),
              const KGap.xl(),
            ],
          ),
        ),
      ),
    );
  }
}
