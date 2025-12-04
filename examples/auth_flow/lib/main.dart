import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:auth_flow/ui/login_page.dart';
import 'package:auth_flow/ui/my_home_page.dart';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(providers: [sharedPreferenceProvider(prefs)], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [AuthNotifier.provider],
      child: SignalBuilder(
        builder: (context, child) {
          final controller = AuthNotifier.provider.of(context);

          // Listen to auth state changes and navigate accordingly
          Effect(() {
            final isLoggedIn = controller.isLoggedIn.value;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final navigator = navigatorKey.currentState;
              if (navigator == null) return;

              if (!isLoggedIn) {
                navigator.popUntil((route) => route.isFirst);
              }
            });
          });

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Auth Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
            home: controller.isLoggedIn.value ? const MyHomePage(title: 'Home') : const LoginPage(),
          );
        },
      ),
    );
  }
}
