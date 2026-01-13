import 'package:flutter/foundation.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Signal listenable notifies listeners and stops after removal', () {
    final signal = Signal(0);
    var calls = 0;

    void listener() => calls++;

    signal.addListener(listener);
    expect(calls, 0);

    signal.value = 1;
    expect(calls, 1);

    signal.value = 2;
    expect(calls, 2);

    signal.removeListener(listener);
    signal.value = 3;
    expect(calls, 2);

    signal.dispose();
  });

  test('Signal listenable disposes effect on signal disposal', () {
    final signal = Signal(0);
    var calls = 0;

    void listener() => calls++;

    signal.addListener(listener);
    signal.value = 1;
    expect(calls, 1);

    signal.dispose();
  });

  test('LazySignal wrapper is constructed', () {
    final lazy = LazySignal<int>();
    expect(lazy.isInitialized, isFalse);

    lazy.value = 10;
    expect(lazy.value, 10);

    lazy.dispose();
  });

  test('Resource.stream wrapper constructs and disposes', () {
    final resource = Resource.stream(
      () => Stream<int>.value(1),
    );

    expect(resource, isA<Listenable>());
    resource.dispose();
  });
}
