import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'pages/use_signal.dart';
import 'pages/use_list_signal.dart';
import 'pages/use_set_signal.dart';
import 'pages/use_map_signal.dart';
import 'pages/use_computed.dart';
import 'pages/use_resource.dart';
import 'pages/use_resource_stream.dart';
import 'pages/use_solidart_effect.dart';
import 'pages/use_existing_signal.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solidart Hooks Examples',
      home: const HookListScreen(),
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
  }
}

@immutable
class HookInfo {
  const HookInfo({
    required this.title,
    required this.description,
    required this.example,
  });

  final String title;
  final String description;
  final Widget Function() example;
}

class HookListScreen extends HookWidget {
  const HookListScreen({super.key});

  static final List<HookInfo> hooks = [
    HookInfo(
      title: 'useSignal',
      description: 'Create a reactive signal with a value',
      example: () => const UseSignalExample(),
    ),
    HookInfo(
      title: 'useListSignal',
      description: 'Create a reactive list signal',
      example: () => const UseListSignalExample(),
    ),
    HookInfo(
      title: 'useSetSignal',
      description: 'Create a reactive set signal',
      example: () => const UseSetSignalExample(),
    ),
    HookInfo(
      title: 'useMapSignal',
      description: 'Create a reactive map signal',
      example: () => const UseMapSignalExample(),
    ),
    HookInfo(
      title: 'useComputed',
      description: 'Create a computed signal that derives from other signals',
      example: () => const UseComputedExample(),
    ),
    HookInfo(
      title: 'useResource',
      description: 'Create a resource from a Future',
      example: () => const UseResourceExample(),
    ),
    HookInfo(
      title: 'useResourceStream',
      description: 'Create a resource from a Stream',
      example: () => const UseResourceStreamExample(),
    ),
    HookInfo(
      title: 'useSolidartEffect',
      description:
          'Create a reactive effect that runs when dependencies change',
      example: () => const UseSolidartEffectExample(),
    ),
    HookInfo(
      title: 'useExistingSignal',
      description: 'Bind an existing signal to the widget',
      example: () => const UseExistingSignalExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solidart Hooks Examples')),
      body: ListView.builder(
        itemCount: hooks.length,
        itemBuilder: (context, index) {
          final hook = hooks[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                hook.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(hook.description),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => hook.example()));
              },
            ),
          );
        },
      ),
    );
  }
}
