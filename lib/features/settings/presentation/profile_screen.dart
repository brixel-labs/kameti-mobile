import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kameti/core/result/failure_message.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/presentation/detail/widgets/async_gate.dart';
import 'package:kameti/features/settings/data/profile_providers.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// The signed-in user's profile (board AF-Profile): name, how many kametis
/// they run and belong to, and sign-out.
class ProfileScreen extends ConsumerWidget {
  const new({super.key});

  void _retry(WidgetRef ref) => ref
    ..invalidate(myProfileProvider)
    ..invalidate(myKametisProvider);

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showKConfirm(
      context,
      title: l10n.profileSignOutTitle,
      message: l10n.profileSignOutBody,
      confirmLabel: l10n.profileSignOut,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showToast(
        failureMessage(l10n, failure),
        tone: KToastTone.negative,
      );
    }
    // On success the router redirect moves to sign-in.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final k = context.k;
    final profile = ref.watch(myProfileProvider);
    final kametis = ref.watch(myKametisProvider);
    final userId = ref.watch(currentUserIdProvider);
    return KScaffold(
      appBar: KAppBar(title: l10n.profileTitle),
      body: AsyncGate(
        values: [profile, kametis, userId],
        onRetry: () => _retry(ref),
        builder: (context, offline) {
          final me = profile.requireValue;
          final all = kametis.requireValue;
          final running = all.where((x) => x.isOwnedBy(userId.value)).length;
          return ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpace.gutter,
              KSpace.lg,
              KSpace.gutter,
              KSpace.xxxl,
            ),
            children: [
              if (offline != null) ...[offline, const KGap.md()],
              Column(
                children: [
                  KAvatar(
                    name: me.displayName,
                    colorIndex: 0,
                    size: KAvatarSize.lg,
                    imageUrl: me.avatarUrl,
                  ),
                  const KGap.md(),
                  Text(me.displayName, style: k.text.titleLg),
                ],
              ),
              const KGap.xl(),
              KCard(
                child: KKeyValueList(
                  items: [
                    KKeyValue(l10n.profileRunning, value: '$running'),
                    KKeyValue(
                      l10n.profileMember,
                      value: '${all.length - running}',
                    ),
                  ],
                ),
              ),
              const KGap.xl(),
              KSectionHeader(title: l10n.profileAccount),
              KButton.secondary(
                label: l10n.profileSignOut,
                icon: Icons.logout,
                expand: true,
                onPressed: () => _signOut(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }
}
