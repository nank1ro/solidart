import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solidart/deps/preset.dart' as preset;

class _ThrowAfterBuildSignalBuilder extends SignalBuilder {
  const _ThrowAfterBuildSignalBuilder({required this.signal})
    : super(builder: _noopBuilder);

  final Signal<int> signal;

  static Widget _noopBuilder(BuildContext context, Widget? child) {
    return child ?? const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    signal.value;
    super.build(context);
    throw StateError('boom');
  }
}

void main() {
  testWidgets('SignalBuilder restores context when builder throws', (
    tester,
  ) async {
    final prevDetach = SolidartConfig.detachEffects;
    SolidartConfig.detachEffects = false;
    addTearDown(() => SolidartConfig.detachEffects = prevDetach);

    final signal = Signal(0);
    await tester.pumpWidget(
      MaterialApp(
        home: SignalBuilder(
          builder: (context, child) {
            signal.value;
            throw StateError('boom');
          },
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(SolidartConfig.detachEffects, isFalse);
    expect(preset.getActiveSub(), isNull);
  });

  testWidgets(
    'SignalBuilder cleans up dependencies when build throws',
    (tester) async {
      final prevAutoDispose = SolidartConfig.autoDispose;
      SolidartConfig.autoDispose = true;
      addTearDown(() => SolidartConfig.autoDispose = prevAutoDispose);

      final signal = Signal(0);
      await tester.pumpWidget(
        MaterialApp(
          home: _ThrowAfterBuildSignalBuilder(signal: signal),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<StateError>());

      await tester.pumpWidget(const SizedBox());
      expect(signal.isDisposed, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 1)),
  );
}
