import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:kameti/core/env/env.dart';
import 'package:kameti/features/audit/presentation/activity_screen.dart';
import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/auth/presentation/sign_in_screen.dart';
import 'package:kameti/features/home/presentation/home_screen.dart';
import 'package:kameti/features/invites/presentation/join_screen.dart';
import 'package:kameti/features/kameti/presentation/create/create_kameti_screen.dart';
import 'package:kameti/features/kameti/presentation/detail/kameti_detail_screen.dart';
import 'package:kameti/features/payments/presentation/record_payment_screen.dart';
import 'package:kameti/features/payments/presentation/record_payout_screen.dart';
import 'package:kameti/features/payments/presentation/settle_screen.dart';
import 'package:kameti/features/settings/presentation/profile_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Every route in the app. Build locations with the helpers, never by hand.
abstract final class Routes {
  static const home = '/';
  static const signIn = '/sign-in';

  /// Invite deep link: `https://www.fhbtechservices.com/kameti/join/<token>`
  static const join = '/kameti/join/:token';

  static const createKameti = '/kameti/new';
  static const profile = '/profile';
  static const kametiDetail = '/kameti/:kametiId';
  static const setupKameti = '/kameti/:kametiId/setup';
  static const activity = '/kameti/:kametiId/activity';
  static const recordPayment = '/kameti/:kametiId/pay';
  static const settle = '/kameti/:kametiId/settle';
  static const recordPayout = '/kameti/:kametiId/payout/:month';

  static String kameti(String id) => '/kameti/$id';

  /// An invite link token, or the 6-character code typed by hand.
  static String joinFor(String tokenOrCode) =>
      '/kameti/join/${Uri.encodeComponent(tokenOrCode)}';

  /// Reopens a draft in the create wizard.
  static String setup(String kametiId) => '/kameti/$kametiId/setup';
  static String activityFor(String kametiId) => '/kameti/$kametiId/activity';

  /// Optionally preselects a member.
  static String pay(String kametiId, {String? memberId}) => memberId == null
      ? '/kameti/$kametiId/pay'
      : '/kameti/$kametiId/pay?member=$memberId';
  static String settleFor(String kametiId) => '/kameti/$kametiId/settle';
  static String payout(String kametiId, int month) =>
      '/kameti/$kametiId/payout/$month';
}

@riverpod
GoRouter router(Ref ref) {
  // Without a backend (no env file) the app runs UI-only, with no sign-in.
  final auth = Env.hasBackend ? ref.watch(authRepositoryProvider) : null;
  final refresh = _StreamRefresh(auth?.userIdChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: auth == null ? Routes.signIn : Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (auth == null) return null;
      final signedIn = auth.currentUserId != null;
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!signedIn && !atSignIn) {
        // Remember where they were going (an invite link, say) so sign-in
        // can carry on there.
        final target = state.uri.toString();
        return target == Routes.home
            ? Routes.signIn
            : Uri(
                path: Routes.signIn,
                queryParameters: {'from': target},
              ).toString();
      }
      if (signedIn && atSignIn) {
        final from = state.uri.queryParameters['from'];
        // Only paths inside the app, never another site.
        final inApp =
            from != null && from.startsWith('/') && !from.startsWith('//');
        return inApp ? from : Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.join,
        builder: (context, state) =>
            JoinScreen(token: state.pathParameters['token'] ?? ''),
      ),
      // `/kameti/new` must come before `/kameti/:kametiId`.
      GoRoute(
        path: Routes.createKameti,
        builder: (context, state) => const CreateKametiScreen(),
      ),
      GoRoute(
        path: Routes.kametiDetail,
        builder: (context, state) =>
            KametiDetailScreen(kametiId: state.pathParameters['kametiId']!),
        routes: [
          GoRoute(
            path: 'setup',
            builder: (context, state) =>
                CreateKametiScreen(draftId: state.pathParameters['kametiId']),
          ),
          GoRoute(
            path: 'activity',
            builder: (context, state) =>
                ActivityScreen(kametiId: state.pathParameters['kametiId']!),
          ),
          GoRoute(
            path: 'pay',
            builder: (context, state) => RecordPaymentScreen(
              kametiId: state.pathParameters['kametiId']!,
              memberId: state.uri.queryParameters['member'],
            ),
          ),
          GoRoute(
            path: 'settle',
            builder: (context, state) =>
                SettleScreen(kametiId: state.pathParameters['kametiId']!),
          ),
          GoRoute(
            path: 'payout/:month',
            builder: (context, state) => RecordPayoutScreen(
              kametiId: state.pathParameters['kametiId']!,
              month: int.parse(state.pathParameters['month']!),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Re-runs the redirect whenever the signed-in user changes.
class _StreamRefresh extends ChangeNotifier {
  new(Stream<Object?>? stream) {
    _sub = stream?.listen((_) => notifyListeners());
  }

  StreamSubscription<Object?>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
