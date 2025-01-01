import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _themeModeId = ProviderId<Signal<ThemeMode>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the theme mode signal to descendats
    return ProviderScope.builder(
      providers: [
        _themeModeId.createProvider(
          init: () => Signal(ThemeMode.light),
        ),
      ],
      // using the builder method to immediately access the signal
      builder: (context) {
        // observe the theme mode value this will rebuild every time the themeMode signal changes.
        final themeMode = _themeModeId.observe(context).value;
        return MaterialApp(
          title: 'Toggle theme',
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // retrieve the theme mode signal
    final themeMode = _themeModeId.get(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toggle theme'),
      ),
      body: Center(
        child:
            // Listen to the theme mode signal rebuilding only the IconButton
            SignalBuilder(
          builder: (_, __) {
            final mode = themeMode();
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
