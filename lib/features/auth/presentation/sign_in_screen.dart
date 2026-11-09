import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/app/router.dart';
import 'package:kameti/core/env/env.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/auth/data/dev_accounts.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Sign-in screen (board: AF-Sign-In).
///
/// Apple and Google sign-in arrive once their credentials exist. In the dev
/// flavor with a local backend, two extra buttons sign in as the seeded
/// test accounts.
class SignInScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String? _busyEmail;

  bool get _devSignIn => Env.flavor == Flavor.dev && Env.hasBackend;

  Future<void> _signInAs(String email) async {
    setState(() => _busyEmail = email);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithPassword(email, DevAccounts.password);
    if (!mounted) return;
    setState(() => _busyEmail = null);
    if (result case Err(:final failure)) {
      context.showToast(
        failureMessage(AppLocalizations.of(context), failure),
        tone: KToastTone.negative,
      );
    }
    // On success the router redirect moves to Home.
  }

  void _providerSignIn() {
    if (Env.hasBackend) {
      context.showToast(AppLocalizations.of(context).comingSoon);
    } else {
      context.go(Routes.home);
    }
  }

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
                onPressed: _providerSignIn,
              ),
              const KGap.sm(),
              KButton.secondary(
                label: l10n.continueWithGoogle,
                expand: true,
                onPressed: _providerSignIn,
              ),
              if (_devSignIn) ...[
                const KGap.lg(),
                KButton.secondary(
                  label: l10n.devSignInOwner,
                  expand: true,
                  isLoading: _busyEmail == DevAccounts.owner,
                  onPressed: _busyEmail == null
                      ? () => _signInAs(DevAccounts.owner)
                      : null,
                ),
                const KGap.sm(),
                KButton.secondary(
                  label: l10n.devSignInMember,
                  expand: true,
                  isLoading: _busyEmail == DevAccounts.member,
                  onPressed: _busyEmail == null
                      ? () => _signInAs(DevAccounts.member)
                      : null,
                ),
              ],
              const KGap.xl(),
            ],
          ),
        ),
      ),
    );
  }
}
