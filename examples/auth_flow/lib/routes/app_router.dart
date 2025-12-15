import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:auth_flow/ui/home_page.dart';
import 'package:auth_flow/ui/login_page.dart';
import 'package:auth_flow/ui/profile_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(this.authNotifier);

  final AuthNotifier authNotifier;

  late final router = GoRouter(
    refreshListenable: authNotifier.isLoggedIn,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn.value;
      if (!isLoggedIn && state.matchedLocation != '/login') {
        return '/login';
      }
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const HomePage(title: 'Home'),
        routes: [GoRoute(path: 'profile', builder: (_, _) => const ProfilePage())],
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    ],
  );
}
