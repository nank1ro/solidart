import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final aProvider =
    Provider.withArgument<int, String>((context, str) => int.parse(str));
final bProvider =
    Provider.withArgument<int, String>((context, str) => int.parse(str));

class SameTypePage extends StatefulWidget {
  const SameTypePage({super.key});

  @override
  State<SameTypePage> createState() => _SameTypePageState();
}

class _SameTypePageState extends State<SameTypePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProviderScope(
        providers: [
          aProvider('10'),
          bProvider('20'),
        ],
        builder: (context) {
          final a = aProvider.get(context);
          final b = aProvider.get(context);
          return Text('a: $a, b: $b');
        },
      ),
    );
  }
}
