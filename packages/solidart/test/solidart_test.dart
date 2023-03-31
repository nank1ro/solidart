import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/core/read_signal.dart';
import 'package:solidart/src/core/resource.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:test/test.dart';

import 'package:collection/collection.dart';

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

class User {
  final int id;

  User({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}

class SampleList {
  final List<int> numbers;

  SampleList(this.numbers);
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

    test('check Signal becomes ReadSignal', () {
      final s = createSignal(0);
      expect(s, TypeMatcher<Signal<int>>());
      expect(s.toReadSignal(), TypeMatcher<ReadSignal<int>>());
      // ignore: deprecated_member_use_from_same_package
      expect(s.readable, TypeMatcher<ReadSignal<int>>());
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

    test('custom signal options for derived signal', () async {
      final a = createSignal(SampleList([1]));
      final selected = a.select(
        (value) => value.numbers,
        options: SignalOptions<List<int>>(
          comparator: (a, b) => ListEquality().equals(a, b),
        ),
      );

      final cb = MockCallbackFunction();
      createEffect(cb, signals: [selected]);

      verifyNever(cb());

      a.value = SampleList([1]);
      await pumpEventQueue();
      verifyNever(cb());

      a.value = SampleList([1, 2]);
      await pumpEventQueue();
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

  group('ReadSignal tests', () {
    test('check ReadSignal value and listener count', () {
      final s = ReadSignal(0);
      expect(s.value, 0);
      expect(s.previousValue, null);
      expect(s.listenerCount, 0);

      createEffect(() {}, signals: [s]);
      expect(s.listenerCount, 1);
    });

    test('check toString()', () {
      final s = ReadSignal(0);
      expect(s.toString(),
          "ReadSignal<int>(value: 0, previousValue: null, options; SignalOptions<int>(equals: false, comparator: PRESENT))");
    });
  });

  group('Resource tests', () {
    test('check createResource with stream', () async {
      final streamController = StreamController<int>();
      addTearDown(() => streamController.close());

      final resource = createResource(stream: streamController.stream);
      expect(resource.value, isA<ResourceUnresolved<int>>());
      resource.resolve();
      expect(resource.value, isA<ResourceLoading<int>>());
      streamController.add(1);
      await pumpEventQueue();
      expect(resource.value, isA<ResourceReady<int>>());
      expect(resource.value.value, 1);

      streamController.add(10);
      await pumpEventQueue();
      expect(resource.value, isA<ResourceReady<int>>());
      expect(resource.value(), 10);

      streamController.addError(UnimplementedError());
      await pumpEventQueue();
      expect(resource.value, isA<ResourceError<int>>());
      expect(resource.value.error, isUnimplementedError);
    });

    test('check createResource with future that throws', () async {
      Future<User> getUser() => throw Exception();
      final resource = createResource(fetcher: getUser);

      addTearDown(resource.dispose);

      await resource.resolve();
      await pumpEventQueue();
      expect(resource.value, isA<ResourceError<User>>());
      expect(resource.value.error, isException);
    });

    test('check createResource with future', () async {
      final userId = createSignal(0);

      Future<User> getUser() {
        if (userId.value == 2) throw Exception();
        return Future.value(User(id: userId.value));
      }

      final resource = createResource(fetcher: getUser, source: userId);

      await resource.resolve();
      await pumpEventQueue();
      expect(resource.value, isA<ResourceReady<User>>());
      expect(resource.value.value, User(id: 0));

      userId.value = 1;
      await pumpEventQueue();
      expect(resource.value, isA<ResourceReady<User>>());
      expect(resource.value(), User(id: 1));

      userId.value = 2;
      await pumpEventQueue();
      expect(resource.value, isA<ResourceError<User>>());
      expect(resource.value.error, isException);

      userId.value = 3;
      await pumpEventQueue();
      await resource.refetch();
      expect(resource.value, isA<ResourceReady<User>>());
      expect(resource.value.hasError, false);
      expect(resource.value.asError, isNull);
      expect(resource.value.isLoading, false);
      expect(resource.value.asReady, isNotNull);
      expect(resource.value.isReady, true);

      resource.value.on(
        ready: (data, refreshing) {},
        error: (error, stack) {},
        loading: () {},
      );

      resource.dispose();
    });

    test('check ResourceValue.on', () async {
      bool shouldThrow = false;
      Future<int> fetcher() {
        return Future.delayed(const Duration(milliseconds: 150), () {
          if (shouldThrow) throw Exception();
          return 0;
        });
      }

      var dataCalledTimes = 0;
      var loadingCalledTimes = 0;
      var errorCalledTimes = 0;
      var refreshingTrueTimes = 0;
      final resource = createResource(fetcher: fetcher);

      createEffect(() {
        resource.value.on(ready: (data, refreshing) {
          if (refreshing) {
            refreshingTrueTimes++;
          } else {
            dataCalledTimes++;
          }
        }, error: (error, stackTrace) {
          errorCalledTimes++;
        }, loading: () {
          loadingCalledTimes++;
        });
      }, signals: [resource]);

      resource.resolve();
      await Future.delayed(const Duration(milliseconds: 40));
      expect(loadingCalledTimes, 1);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(dataCalledTimes, 1);
      expect(errorCalledTimes, 0);

      resource.refetch();
      await Future.delayed(const Duration(milliseconds: 40));
      expect(refreshingTrueTimes, 1);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(dataCalledTimes, 2);

      expect(resource.value, TypeMatcher<ResourceReady<int>>());
      shouldThrow = true;
      resource.refetch();
      await Future.delayed(const Duration(milliseconds: 150));
      expect(errorCalledTimes, 1);

      resource.refetch();
      await Future.delayed(const Duration(milliseconds: 150));
      expect(loadingCalledTimes, 2);
    });

    test('check toString()', () async {
      final r = createResource(fetcher: () => Future.value(1));
      await r.resolve();
      await pumpEventQueue();
      expect(r.toString(),
          "Resource<int>(value: ResourceReady<int>(value: 1, refreshing: false), previousValue: ResourceLoading<int>(), options; SignalOptions<ResourceValue<int>>(equals: false, comparator: PRESENT))");
    });
  });
}
