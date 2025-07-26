import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_test/flutter_test.dart';

class MyEffectClass {
  MyEffectClass(this.signal) {
    Effect(() {
      effectRun++;
      debugPrint('Signal value: ${signal.value}');
    });
  }

  int effectRun = 0;

  final Signal<int> signal;
}

void main() {
  testWidgets(
    'Effect inside SignalBuilder reacts',
    (tester) async {
      final counter = Signal(0);

      MyEffectClass? cls;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalBuilder(
              builder: (_, __) {
                cls ??= MyEffectClass(counter);
                return Text(cls!.signal.value.toString());
              },
            ),
          ),
        ),
      );

      expect(cls!.effectRun, 1);
      expect(find.text('0'), findsOneWidget);

      counter.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(cls!.effectRun, 2);

      counter.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(cls!.effectRun, 3);
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );
}
