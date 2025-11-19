import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final themeModeProvider = Provider<Signal<ThemeMode>>(
  (_) => Signal(ThemeMode.dark),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the theme mode signal to descendats
    return ProviderScope(
      providers: [themeModeProvider],
      // using the builder method to immediately access the signal
      child: SignalBuilder(
        builder: (context, _) {
          // observe the theme mode value this will rebuild every time the themeMode signal changes.
          final themeMode = themeModeProvider.of(context).value;
          return MaterialApp(
            title: 'Toggle theme',
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // retrieve the theme mode signal
    final themeMode = themeModeProvider.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Toggle theme')),
      body: Center(
        child:
            // Listen to the theme mode signal rebuilding only the IconButton
            SignalBuilder(
              builder: (_, _) {
                final mode = themeMode.value;
                return IconButton(
                  onPressed: () {
                    // toggle the theme mode
                    if (mode == ThemeMode.light) {
                      themeMode.value = ThemeMode.dark;
                    } else {
                      themeMode.value = ThemeMode.light;
                    }
                  },
                  icon: Icon(
                    mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  ),
                );
              },
            ),
      ),
    );
  }
}
