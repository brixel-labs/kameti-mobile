import 'package:go_router/go_router.dart';
import 'package:kameti/features/auth/presentation/sign_in_screen.dart';
import 'package:kameti/features/home/presentation/home_screen.dart';
import 'package:kameti/features/invites/presentation/join_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

abstract final class Routes {
  static const home = '/';
  static const signIn = '/sign-in';

  /// Invite deep link: `https://www.fhbtechservices.com/kameti/join/<token>`
  static const join = '/kameti/join/:token';
}

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: Routes.signIn,
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
        path: Routes.join,
        builder: (context, state) =>
            JoinScreen(token: state.pathParameters['token'] ?? ''),
      ),
    ],
  );
}
