import 'package:example/pages/advanced_effects.dart';
import 'package:example/pages/counter.dart';
import 'package:example/pages/derived_signal.dart';
import 'package:example/pages/dual_signal_builder.dart';
import 'package:example/pages/effects.dart';
import 'package:example/pages/resource.dart';
import 'package:example/pages/show.dart';
import 'package:example/pages/signals_in_modals.dart';
import 'package:example/pages/solid.dart';
import 'package:example/pages/solid_reactivity.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: routes,
    );
  }
}

// Maps the routes to the specific widget page.
final routes = <String, WidgetBuilder>{
  '/counter': (_) => const CounterPage(),
  '/show': (_) => const ShowPage(),
  '/derived-signal': (_) => const DerivedSignalsPage(),
  '/effects': (_) => const EffectsPage(),
  '/dual-signal-builder': (_) => const DualSignalBuilderPage(),
  '/resource': (_) => const ResourcePage(),
  '/solid': (_) => const SolidPage(),
  '/advanced-effects': (_) => const AdvancedEffectsPage(),
  '/solid-reactivity': (_) => const SolidReactivity(),
  '/signals-in-modals': (_) => const SignalsInModals(),
};
final routeToNameRegex = RegExp('(?:^/|-)([a-z])');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = routes.keys;
    return Scaffold(
      appBar: AppBar(title: const Text('Solidart showcase')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (BuildContext context, int index) {
          final route = keys.elementAt(index);

          final name = route.replaceAllMapped(
            routeToNameRegex,
            (match) => match.group(0)!.substring(1).toUpperCase(),
          );

          return ListTile(
            title: Text(name),
            onTap: () {
              Navigator.of(context).pushNamed(route);
            },
          );
        },
      ),
    );
  }
}
