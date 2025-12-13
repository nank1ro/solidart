import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:auth_flow/ui/login_page.dart';
import 'package:auth_flow/ui/home_page.dart';
import 'package:auth_flow/ui/profile_page.dart';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localstorage/localstorage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();

  runApp(ProviderScope(providers: [AuthNotifier.provider], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    router = AppRouter(context).router;
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Auth Demo - GoRouter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      routerConfig: router,
    );
  }
}

class AppRouter {
  AppRouter(this.context);

  final BuildContext context;

  late final router = GoRouter(
    refreshListenable: AuthNotifier.provider.of(context).isLoggedIn,
    redirect: (context, state) {
      final isLoggedIn = AuthNotifier.provider.of(context).isLoggedIn.value;
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
