import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/design_system/design_system.dart';
import 'package:kameti/features/inbox/data/inbox_providers.dart';
import 'package:kameti/l10n/gen/app_localizations.dart';

/// The signed-in frame: the current tab above the bottom navigation
/// (Home · Inbox · Profile). Kameti screens open over it, full screen.
class AppShell extends ConsumerWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final needsAttention = ref.watch(inboxCountProvider) > 0;
    // A plain Scaffold on purpose: each tab is a KScaffold with its own
    // app bar and safe areas, which a KScaffold here would pad twice.
    return Scaffold(
      backgroundColor: context.k.colors.background,
      body: shell,
      bottomNavigationBar: KBottomNav(
        currentIndex: shell.currentIndex,
        // Tapping the current tab goes back to its first screen.
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          KNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.navHome,
          ),
          KNavItem(
            icon: Icons.inbox_outlined,
            selectedIcon: Icons.inbox,
            label: l10n.navInbox,
            showDot: needsAttention,
          ),
          KNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
