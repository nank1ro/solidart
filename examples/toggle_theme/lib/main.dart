import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(const MyApp());
}

/// The identifiers used for [Solid] signals.
enum SignalId {
  themeMode,
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the theme mode signal to descendats
    return Solid(
      signals: {
        SignalId.themeMode: () => createSignal<ThemeMode>(ThemeMode.light),
      },
      child:
          // using a builder here because the `context` must be a descendant of [Solid]
          Builder(
        builder: (context) {
          // observe the theme mode value this will rebuild every time the themeMode signal changes.
          final themeMode = context.observe<ThemeMode>(SignalId.themeMode);
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
    final themeMode = context.getSignal<Signal<ThemeMode>>(SignalId.themeMode);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toggle theme'),
      ),
      body: Center(
        child:
            // Listen to the theme mode signal rebuilding only the IconButton
            SignalBuilder(
          signal: themeMode,
          builder: (_, mode, __) {
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
                mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
              ),
            );
          },
        ),
      ),
    );
  }
}
