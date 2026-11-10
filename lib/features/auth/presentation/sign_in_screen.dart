import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/env/env.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/auth/data/dev_accounts.dart';
import 'package:kameti/features/auth/presentation/widgets/google_logo.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// Sign-in screen (board: AF-Sign-In).
///
/// Continue with Apple (Apple platforms only) and Google, both native
/// flows that end in `signInWithIdToken`. In the dev flavor with a local
/// backend, two extra buttons sign in as the seeded test accounts.
class SignInScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Provider { apple, google }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String? _busyEmail;
  _Provider? _busyProvider;

  bool get _devSignIn => Env.flavor == Flavor.dev && Env.hasBackend;

  /// The message for [failure]. Debug builds add the raw cause (for example
  /// "Unacceptable audience in id_token") so a setup mistake is visible.
  void _showFailure(Failure failure) {
    final message = failureMessage(AppLocalizations.of(context), failure);
    final detail = kDebugMode && failure is SignInFailure
        ? failure.detail
        : null;
    context.showToast(
      detail == null ? message : '$message\n$detail',
      tone: KToastTone.negative,
      duration: Duration(seconds: detail == null ? 4 : 15),
    );
  }

  Future<void> _signInAs(String email) async {
    setState(() => _busyEmail = email);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithPassword(email, DevAccounts.password);
    if (!mounted) return;
    setState(() => _busyEmail = null);
    if (result case Err(:final failure)) _showFailure(failure);
    // On success the router redirect moves to Home.
  }

  Future<void> _providerSignIn(_Provider provider) async {
    final auth = ref.read(authRepositoryProvider);
    setState(() => _busyProvider = provider);
    final result = switch (provider) {
      _Provider.apple => await auth.signInWithApple(),
      _Provider.google => await auth.signInWithGoogle(),
    };
    if (!mounted) return;
    setState(() => _busyProvider = null);
    // Ok(false) = closed the sheet: nothing to say. On success the router
    // redirect moves on. Every failure has a message the user can act on.
    if (result case Err(:final failure)) _showFailure(failure);
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
              if (!Env.hasBackend) ...[
                // Started without --dart-define-from-file: nothing to sign
                // in to, so say so instead of pretending.
                KInfoBanner(
                  tone: KBannerTone.warning,
                  message: kDebugMode
                      ? '${l10n.signInNoBackend}\n${l10n.signInNoBackendHint}'
                      : l10n.signInNoBackend,
                ),
                const KGap.md(),
              ],
              if (AuthRepository.supportsApple) ...[
                KButton.primary(
                  label: l10n.continueWithApple,
                  icon: Icons.apple,
                  expand: true,
                  isLoading: _busyProvider == _Provider.apple,
                  onPressed: _busyProvider == null && Env.hasBackend
                      ? () => _providerSignIn(_Provider.apple)
                      : null,
                ),
                const KGap.sm(),
              ],
              KButton.secondary(
                label: l10n.continueWithGoogle,
                leading: const GoogleLogo(),
                expand: true,
                isLoading: _busyProvider == _Provider.google,
                onPressed: _busyProvider == null && Env.hasBackend
                    ? () => _providerSignIn(_Provider.google)
                    : null,
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
