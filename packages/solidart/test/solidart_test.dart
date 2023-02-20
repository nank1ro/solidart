import 'package:mockito/mockito.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/core/readable_signal.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:test/test.dart';

class MockCallbackFunction extends Mock {
  void call();
}

class MockCallbackFunctionWithValue<T> extends Mock {
  void call(T value);
}

class _A {
  _A();
}

class _B {
  _B(this.c);
  final _C c;
}

class _C {
  _C(this.count);

  final int count;
}

void main() {
  group('createSignal tests - ', () {
    test('with equals true it notifies only when the value changes', () async {
      final counter =
          createSignal(0, options: const SignalOptions<int>(equals: true));

      final cb = MockCallbackFunction();
      counter.addListener(cb);

      expect(counter.value, 0);

      counter.value = counter.value + 1;
      await pumpEventQueue();
      expect(counter(), 1);
      counter
        ..value = 2
        ..value = 2
        ..value = 2;

      await pumpEventQueue();
      counter.value = 3;

      expect(counter(), 3);
      await pumpEventQueue();
      verify(cb()).called(3);
      // clear
      counter.removeListener(cb);
    });

    test(
        'with the identical comparator it notifies only when the comparator '
        'returns false', () async {
      final signal = createSignal(
        null,
        options: const SignalOptions<_A>(),
      );
      final cb = MockCallbackFunction();
      signal.addListener(cb);

      expect(signal.value, null);
      final a = _A();
      signal
        ..value = a
        ..value = a
        ..value = a;

      await pumpEventQueue();
      signal.value = _A();
      await pumpEventQueue();
      verify(cb()).called(2);

      // clear
      signal.removeListener(cb);
    });

    test('check onDispose callback fired when disposing signal', () {
      final s = createSignal(0);
      final cb = MockCallbackFunction();
      s
        ..onDispose(cb)
        ..dispose();
      verify(cb()).called(1);
    });

    test('check previousValue stores the previous value', () {
      final s = createSignal(0);
      expect(
        s.previousValue,
        null,
        reason: 'The signal should have a null previousValue',
      );

      s.value++;

      expect(
        s.previousValue,
        0,
        reason: 'The signal should have 0 has previousValue',
      );

      s.update((value) => value * 5);
      expect(
        s.previousValue,
        1,
        reason: 'The signal should have 1 has previousValue',
      );
    });

    test('check toString()', () {
      final s = createSignal(0);
      expect(s.toString(),
          "Signal<int>(value: 0, previousValue: null, options; SignalOptions<int>(equals: false, comparator: PRESENT))");
    });

    test('check Signal becomes ReadableSignal', () {
      final s = createSignal(0);
      expect(s, TypeMatcher<Signal<int>>());
      expect(s.readable, TypeMatcher<ReadableSignal<int>>());
    });
  });

  group('createEffect tests = ', () {
    test('check effect reaction', () async {
      final signal1 = createSignal(0);
      final signal2 = createSignal(0);

      final cb = MockCallbackFunctionWithValue<int>();
      createEffect(
        () => cb.call(signal1.value),
        signals: [signal1],
      );
      createEffect(
        () => cb.call(signal2.value),
        signals: [signal2],
      );

      signal1.value = 1;
      await pumpEventQueue();
      verify(cb(1)).called(1);
      signal2.value = 2;
      await pumpEventQueue();
      verify(cb(2)).called(1);
      signal2.value = 4;
      signal1.value = 4;
      await pumpEventQueue();
      verify(cb(4)).called(2);
    });

    test('check effect not called if signal is disposed', () {
      final s = createSignal(0);
      final cb = MockCallbackFunction();
      createEffect(cb, signals: [s]);
      s.dispose();
      verifyNever(cb());
    });

    test('check effect state', () {
      final s = createSignal(0);
      final e = createEffect(() {}, signals: [s]);
      expect(e.state, EffectState.running);
      expect(e.isRunning, true);

      e.pause();
      expect(e.state, EffectState.paused);
      expect(e.isPaused, true);

      e.resume();
      expect(e.state, EffectState.resumed);
      expect(e.isResumed, true);

      e.cancel();
      expect(e.state, EffectState.cancelled);
      expect(e.isCancelled, true);
    });
  });

  group('signalSelector tests - ', () {
    test('check that a signal selector updates only for the selected value',
        () async {
      final klass = _B(_C(0));
      final s = createSignal(klass);
      final selected = s.select((value) => value.c.count);
      final cb = MockCallbackFunctionWithValue<int>();

      void listener() {
        cb(selected.value);
      }

      selected.addListener(listener);

      s.value = _B(_C(1));

      await pumpEventQueue();
      s.value = _B(_C(5));
      await pumpEventQueue();
      s.value = _B(_C(1));
      await pumpEventQueue();

      verify(cb(1)).called(2);
      s.value = _B(_C(2));
      await pumpEventQueue();
      s.value = _B(_C(2));
      await pumpEventQueue();
      s.value = _B(_C(3));
      await pumpEventQueue();
      verify(cb(2)).called(1);
      verify(cb(3)).called(1);

      // clear
      selected.addListener(listener);
    });

    test('selector is disposed when signal disposes', () {
      final s = createSignal(_B(_C(0)));
      final selector = s.select((value) => value.c.count);

      final cb = MockCallbackFunction();
      selector.onDispose(cb);
      s.dispose();

      verify(cb()).called(1);
    });

    test("selector's readable signal contains previous value", () async {
      final signal = createSignal(0);
      final derived = signal.select((value) => value * 2);
      expect(derived.previousValue, null);

      signal.value = 1;
      await pumpEventQueue();
      expect(derived.previousValue, 0);

      signal.value = 2;
      await pumpEventQueue();
      expect(derived.previousValue, 2);

      signal.value = 1;
      await pumpEventQueue();
      expect(derived.previousValue, 4);
    });
  });

  group('ReadableSignal tests', () {
    test('check ReadableSignal value and listener count', () {
      final s = ReadableSignal(0);
      expect(s.value, 0);
      expect(s.previousValue, null);
      expect(s.listenerCount, 0);

      createEffect(() {}, signals: [s]);
      expect(s.listenerCount, 1);
    });

    test('check toString()', () {
      final s = ReadableSignal(0);
      expect(s.toString(),
          "ReadableSignal<int>(value: 0, previousValue: null, options; SignalOptions<int>(equals: false, comparator: PRESENT))");
    });
  });
}
