import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

enum SolidSignalIds {
  counter,
  sentence,
}

class SolidSignalsPage extends StatefulWidget {
  const SolidSignalsPage({super.key});

  @override
  State<SolidSignalsPage> createState() => _SolidSignalsPageState();
}

class _SolidSignalsPageState extends State<SolidSignalsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SolidSignals'),
      ),
      body: Solid(
        providers: [
          SolidSignal<Signal<int>>(create: () => createSignal(0)),
          SolidSignal<Signal<String>>(create: () => createSignal("Hello")),
        ],
        // somewhere deep in the tree
        child: const _Counter(),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  // ignore: unused_element
  const _Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.observe<int>();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(counter.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.update<int>((value) => value++);
            },
            child: const Text('Increase'),
          ),
          const SizedBox(height: 16),
          const _Sentence(),
        ],
      ),
    );
  }
}

class _Sentence extends StatefulWidget {
  // ignore: unused_element
  const _Sentence({super.key});

  @override
  State<_Sentence> createState() => _SentenceState();
}

class _SentenceState extends State<_Sentence> {
  @override
  Widget build(BuildContext context) {
    final sentence = context.get<Signal<String>>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: TextFormField(
            initialValue: sentence.value,
            onChanged: (v) => sentence.value = v,
          ),
        ),
        const SizedBox(height: 16),
        SignalBuilder(
          signal: sentence,
          builder: (_, value, __) {
            return Text(value);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {});
          },
          child: const Text('rebuild'),
        ),
        const SizedBox(height: 16),
        const Text(
            'Notice that even if you rebuild, the sentence signal is being reused and not recreated'),
        const SizedBox(height: 16),
        const Text(
            'NOTE: The signals will be disposed when the Solid that created them disposes itself')
      ],
    );
  }
}
