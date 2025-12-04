import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:auth_flow/ui/login_page.dart';
import 'package:auth_flow/ui/home_page.dart';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      providers: [sharedPreferenceProvider(prefs)],
      child: ProviderScope(providers: [AuthNotifier.provider], child: const MyApp()),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Effect disposeEffect;
  late final controller = AuthNotifier.provider.of(context);

  @override
  void initState() {
    // Listen to auth state changes and navigate accordingly
    disposeEffect = Effect(() {
      final isLoggedIn = controller.isLoggedIn.value;
      if (!isLoggedIn) {
        MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    disposeEffect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: MyApp.navigatorKey,
          title: 'Auth Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
          home: controller.isLoggedIn.value ? const HomePage(title: 'Home') : const LoginPage(),
        );
      },
    );
  }
}
