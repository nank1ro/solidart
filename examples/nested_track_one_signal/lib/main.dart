import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(const ExampleApp());
}

final mode = Signal(ThemeMode.light);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    );
    final darkTheme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      useMaterial3: true,
    );

    return SignalWatcher(
      builder: (_, _) => MaterialApp(
        themeMode: mode.value,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          SignalWatcher(
            builder: (_, _) => SwitchListTile(
              title: const Text("Change Theme"),
              value: mode.value == ThemeMode.light,
              onChanged: (value) =>
                  mode.value = value ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          const SizedBox(height: 16),
          const TabsSection(),
        ],
      ),
    );
  }
}

class TabsSection extends StatelessWidget {
  const TabsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final index = Signal(0);

    return Row(
      spacing: 6,
      children: [
        Expanded(
          child: SignalWatcher(
            builder: (context, child) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: index.value == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              onPressed: () => index.value = 0,
              child: child,
            ),
            child: const Text('Tab 1'),
          ),
        ),
        Expanded(
          child: SignalWatcher(
            builder: (context, child) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: index.value == 1
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              onPressed: () => index.value = 1,
              child: child,
            ),
            child: const Text('Tab 2'),
          ),
        ),
        Expanded(
          child: SignalWatcher(
            builder: (context, child) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: index.value == 2
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              onPressed: () => index.value = 2,
              child: child,
            ),
            child: const Text('Tab 3'),
          ),
        ),
      ],
    );
  }
}
