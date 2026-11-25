// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

class _ReadingObserver extends SolidartObserver {
  _ReadingObserver(this.read);

  final void Function(Computed<int> computed) read;

  @override
  void didCreateSignal(SignalBase<Object?> signal) {}

  @override
  void didUpdateSignal(SignalBase<Object?> signal) {
    if (signal is Computed<int>) read(signal);
  }

  @override
  void didDisposeSignal(SignalBase<Object?> signal) {}
}

// Runs [body] and returns the errors it reports to the current zone.
// Fails if [body] itself throws.
List<(Object, StackTrace)> _reportedErrors(void Function() body) {
  final reported = <(Object, StackTrace)>[];
  var completed = false;
  runZonedGuarded(() {
    body();
    completed = true;
  }, (e, s) => reported.add((e, s)));
  expect(completed, isTrue, reason: 'body threw: $reported');
  return reported;
}

void main() {
  group('Computed error recovery', () {
    test('a Computed whose first evaluation throws recovers after its '
        'dependency changes', () {
      final s = Signal(0);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });

      addTearDown(s.dispose);

      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));

      s.value = 1;
      expect(c.value, 1);
    });

    test('an effect that reads a Computed whose first evaluation throws '
        'reruns after the Computed recovers', () {
      final s = Signal(0);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });
      final seen = <int>[];
      final errors = <Object>[];

      Effect(() => seen.add(c.value), onError: errors.add);

      addTearDown(s.dispose);

      expect(errors.single, isA<SolidartCaughtException>());

      s.value = 1;
      s.value = 2;
      expect(seen, [1, 2]);
    });

    test('an effect that reads a Computed keeps running after the Computed '
        'throws and recovers (#192)', () {
      final s = Signal(1);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });
      final seen = <int>[];

      Effect(() => seen.add(c.value));

      addTearDown(s.dispose);

      Object? thrown;
      try {
        s.value = 0;
      } catch (e) {
        thrown = e;
      }
      s.value = 2;
      s.value = 3;

      expect(thrown, isA<SolidartCaughtException>());
      expect(seen, [1, 2, 3]);
    });

    test('a custom comparator still suppresses notifications for equal '
        'values, and value returns the newest object', () {
      final s = Signal(1);
      final c = Computed(
        () => [s.value ~/ 10, s.value],
        comparator: (a, b) => a?[0] == b?[0],
      );
      var runs = 0;

      Effect(() {
        c.value;
        runs++;
      });

      addTearDown(s.dispose);

      expect(runs, 1);

      s.value = 2;
      expect(runs, 1);
      expect(c.value, [0, 2]);

      s.value = 12;
      expect(runs, 2);
      expect(c.value, [1, 12]);
    });

    test('a comparator that never matches still notifies when the selector '
        'returns the same object', () {
      final s = Signal(0);
      final shared = <int>[];
      final c = Computed(() {
        s.value;
        return shared;
      }, comparator: (a, b) => false);
      var runs = 0;

      Effect(() {
        c.value;
        runs++;
      });

      addTearDown(s.dispose);

      expect(runs, 1);

      s.value = 1;
      expect(runs, 2);
    });

    test('a throwing Computed keeps throwing the same error on repeated reads '
        'while no dependency changes', () {
      final s = Signal(0);
      var selectorRuns = 0;
      final c = Computed(() {
        selectorRuns++;
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });

      addTearDown(s.dispose);

      Object? first;
      Object? second;
      try {
        c.value;
      } catch (e) {
        first = e;
      }
      try {
        c.value;
      } catch (e) {
        second = e;
      }

      expect(first, isA<SolidartCaughtException>());
      expect(second, same(first));
      expect(selectorRuns, 1);
    });

    test('a Computed that succeeds, throws and recovers keeps previousValue '
        'correct', () {
      final s = Signal(1);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value * 10;
      });

      addTearDown(s.dispose);

      expect(c.trackPreviousValue, isTrue);
      expect(c.value, 10);
      expect(c.previousValue, isNull);

      s.value = 0;
      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));

      s.value = 2;
      expect(c.value, 20);
      expect(c.previousValue, 10);

      s.value = 3;
      expect(c.value, 30);
      expect(c.previousValue, 20);
    });
    test('a comparator that reads a signal tracks it as a dependency', () {
      final source = Signal(0);
      final suppress = Signal(true);
      final c = Computed(
        () => source.value,
        comparator: (_, _) => suppress.value,
      );
      final seen = <int>[];

      Effect(() => seen.add(c.value));

      addTearDown(source.dispose);
      addTearDown(suppress.dispose);

      source.value = 1;
      expect(seen, [0]);

      suppress.value = false;
      expect(seen, [0, 1]);
    });

    test('run() throws the selector error to its caller', () {
      final c = Computed<int>(() => throw StateError('selector'));

      expect(c.run, throwsA(isA<SolidartCaughtException>()));
    });

    test('run() still throws its own selector error when a subscriber '
        're-runs the computed successfully while being notified', () {
      final input = Signal(0);
      final c = Computed<int>(() {
        // Untracked: only run() re-evaluates, so the effect cannot fire early.
        if (input.untrackedValue == 1) throw StateError('one');
        return input.untrackedValue;
      });
      var observedFailures = 0;
      final effect = Effect(() {
        try {
          c.value;
          // ignore: avoid_catching_errors
        } on SolidartCaughtException {
          if (++observedFailures == 1) {
            input.value = 2;
            c.run();
          }
        }
      });
      addTearDown(effect.dispose);
      addTearDown(input.dispose);

      input.value = 1;
      expect(c.run, throwsA(isA<SolidartCaughtException>()));
      expect(observedFailures, 1);
    });

    test('run() keeps its selector error when a subscriber throws while '
        'being notified', () {
      var fail = false;
      final c = Computed<int>(() {
        if (fail) throw StateError('selector');
        return 1;
      });
      final effect = Effect(
        () => c.value,
        onError: (_) => throw StateError('subscriber'),
      );
      addTearDown(effect.dispose);
      fail = true;

      Object? thrown;
      final zoneErrors = <Object>[];
      runZonedGuarded(() {
        try {
          c.run();
        } catch (e) {
          thrown = e;
        }
      }, (error, _) => zoneErrors.add(error));

      expect(
        thrown,
        isA<SolidartCaughtException>().having(
          (e) => e.exception.toString(),
          'cause',
          'Bad state: selector',
        ),
      );
      expect(zoneErrors, [isA<StateError>()]);
    });

    test('an autoDispose Computed is disposed with its only source after its '
        'last evaluation threw', () {
      final source = Signal(1);
      final c = Computed(() {
        if (source.value == 0) throw StateError('zero');
        return source.value;
      }, autoDispose: true);
      var cleanups = 0;
      c.onDispose(() => cleanups++);

      expect(c.value, 1);

      source.value = 0;
      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));

      source.dispose();
      expect((c.disposed, cleanups), (true, 1));
    });

    test('an observer that reads untrackedValue sees the recovered value', () {
      final seen = <int>[];
      final observer = _ReadingObserver((c) => seen.add(c.untrackedValue));
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));
      final s = Signal(1);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });

      addTearDown(s.dispose);

      expect(c.value, 1);
      s.value = 0;
      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));
      s.value = 2;
      expect(c.value, 2);
      expect(seen, [2]);
    });

    test('an observer that reads previousValue lets the Computed recover', () {
      final seen = <int?>[];
      final observer = _ReadingObserver((c) => seen.add(c.previousValue));
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));
      final s = Signal(1);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });

      addTearDown(s.dispose);

      expect(c.value, 1);
      s.value = 0;
      expect(() => c.value, throwsA(isA<SolidartCaughtException>()));
      s.value = 2;
      expect(c.value, 2);
      expect(seen, [1]);
    });

    test('a comparator that reads untrackedValue sees the new value', () {
      final s = Signal(1);
      final seen = <int>[];
      late final Computed<int> c;
      c = Computed(
        () => s.value,
        comparator: (a, b) {
          seen.add(c.untrackedValue);
          return a == b;
        },
      );

      addTearDown(s.dispose);

      expect(c.value, 1);
      s.value = 2;
      expect(c.value, 2);
      expect(seen, [2]);
    });

    test('a selector can read its own previous value', () {
      final s = Signal(1);
      final seen = <(int?, bool)>[];
      late final Computed<int> c;
      c = Computed(() {
        seen.add((c.previousValue, c.hasPreviousValue));
        return s.value;
      });

      addTearDown(s.dispose);

      expect(c.value, 1);
      s.value = 2;
      expect(c.value, 2);
      expect(seen, [(null, false), (1, true)]);
    });

    test('an autoDispose Computed keeps the child effect it created', () {
      final source = Signal(0);
      final seen = <int>[];
      final owner = Computed(() {
        Effect(() => seen.add(source.value));
        return 1;
      }, autoDispose: true);

      addTearDown(source.dispose);

      expect(owner.value, 1);
      source.value = 1;
      expect(seen, [0, 1]);

      owner.dispose();
      source.value = 2;
      expect(seen, [0, 1]);
    });

    test('a first run() tracks a signal read only by the comparator', () {
      var sampled = 1;
      final gate = Signal(true);
      final c = Computed(() => sampled, comparator: (_, _) => gate.value);

      addTearDown(gate.dispose);

      c.run();
      sampled = 2;
      gate.value = false;
      expect(c.value, 2);
    });

    test('a comparator error is reported to the zone, and the new value is '
        'kept as a change', () {
      final source = Signal(0);
      final error = ArgumentError('invalid comparison');
      final trace = StackTrace.current;
      final c = Computed(
        () => source.value,
        comparator: (_, _) => Error.throwWithStackTrace(error, trace),
      );
      var runs = 0;

      addTearDown(source.dispose);

      final reported = _reportedErrors(() {
        final effect = Effect(() {
          c.value;
          runs++;
        });
        addTearDown(effect.dispose);

        expect(c.value, 0);
        expect(runs, 1);
        source.value = 1;
        expect(c.value, 1);
        expect(runs, 2);
      });

      expect(reported, hasLength(1));
      expect(reported.single.$1, same(error));
      expect(reported.single.$2.toString(), trace.toString());
    });

    test('run() with a throwing comparator reports the error to the zone', () {
      final source = Signal(0);
      final error = ArgumentError('invalid comparison');
      final c = Computed(
        () => source.value,
        comparator: (_, _) => throw error,
      );

      addTearDown(source.dispose);

      final reported = _reportedErrors(() {
        expect(c.value, 0);
        source.value = 1;
        c.run();
        expect(c.value, 1);
      });

      expect(reported.map((r) => r.$1), [same(error)]);
    });

    test('the read that auto-disposes the computed returns the value when the '
        'comparator throws', () {
      final source = Signal(0);
      final error = ArgumentError('invalid comparison');
      var useSource = true;
      final c = Computed(
        () => useSource ? source.value : 1,
        autoDispose: true,
        comparator: (_, _) => throw error,
      );

      addTearDown(source.dispose);

      final reported = _reportedErrors(() {
        expect(c.value, 0);
        expect(c.disposed, isFalse);
        // The next evaluation reads no signal, so the read disposes the
        // computed.
        useSource = false;
        source.value = 1;
        expect(c.value, 1);
        expect(c.disposed, isTrue);
      });

      expect(reported.map((r) => r.$1), [same(error)]);
    });

    test('an observer that reads value during the update notification does '
        'not get the comparator error', () {
      final seen = <int>[];
      final observer = _ReadingObserver((c) => seen.add(c.value));
      final source = Signal(0);
      final error = ArgumentError('invalid comparison');
      final c = Computed(
        () => source.value,
        comparator: (_, _) => throw error,
      );

      addTearDown(source.dispose);

      final reported = _reportedErrors(() {
        expect(c.value, 0);
        SolidartConfig.observers.add(observer);
        addTearDown(() => SolidartConfig.observers.remove(observer));
        source.value = 1;
        expect(c.value, 1);
      });

      expect(seen, [1]);
      expect(reported.map((r) => r.$1), [same(error)]);
    });

    test('a selector error after a comparator error is still thrown', () {
      final source = Signal(0);
      final error = ArgumentError('invalid comparison');
      final c = Computed(() {
        if (source.value == 2) throw StateError('selector');
        return source.value;
      }, comparator: (_, _) => throw error);

      addTearDown(source.dispose);

      final reported = _reportedErrors(() {
        expect(c.value, 0);
        source.value = 1;
        expect(c.value, 1);
        source.value = 2;
        expect(
          () => c.value,
          throwsA(
            isA<SolidartCaughtException>().having(
              (e) => e.exception,
              'exception',
              isA<StateError>(),
            ),
          ),
        );
        expect(c.run, throwsA(isA<SolidartCaughtException>()));
      });

      expect(reported.map((r) => r.$1), [same(error)]);
    });

    test('an observer that runs the Computed again during the update '
        'notification does not hide the change from an effect', () {
      var reran = false;
      final observer = _ReadingObserver((c) {
        if (reran) return;
        reran = true;
        c.run();
      });
      final source = Signal(0);
      final c = Computed(() => source.value);
      final seen = <int>[];

      addTearDown(source.dispose);

      final effect = Effect(() => seen.add(c.value));
      addTearDown(effect.dispose);
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));

      source.value = 1;
      expect(seen, [0, 1]);
    });

    test('a signal that an observer reads during the update notification is '
        'not a dependency of the effect that reads the Computed', () {
      final source = Signal(0);
      final audit = Signal(0);
      final observer = _ReadingObserver((_) => audit.value);
      final c = Computed(() => source.value);
      var runs = 0;

      addTearDown(source.dispose);
      addTearDown(audit.dispose);

      expect(c.value, 0);
      source.value = 1;
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));
      // The effect's read evaluates the Computed and notifies the observer.
      final effect = Effect(() {
        c.value;
        runs++;
      });
      addTearDown(effect.dispose);

      audit.value = 1;
      expect(runs, 1);
    });

    test('a comparator that reads value untracked sees the new value', () {
      final s = Signal(1);
      final seen = <int>[];
      late final Computed<int> c;
      c = Computed(
        () => s.value,
        comparator: (a, b) {
          seen.add(untracked(() => c.value));
          return a == b;
        },
      );

      addTearDown(s.dispose);

      expect(c.value, 1);
      s.value = 2;
      expect(c.value, 2);
      expect(seen, [2]);
    });

    test('an effect created while the selector runs tracks the Computed', () {
      final source = Signal(0);
      final gate = Signal(false);
      final c = Computed(() {
        final value = source.value;
        if (value == 1) gate.value = true;
        return value;
      });
      final seen = <int>[];
      final effect = Effect(() {
        if (gate.value) seen.add(c.value);
      });
      addTearDown(effect.dispose);

      expect(c.value, 0);
      source.value = 1;
      expect(c.value, 1);
      source.value = 2;
      expect(seen.last, 2);
    });

    test('an effect that first reads previousValue while the selector runs '
        'tracks the Computed', () {
      final source = Signal(0);
      final gate = Signal(false);
      final c = Computed(() {
        final value = source.value;
        if (value == 1) gate.value = true;
        return value;
      });
      final seen = <int?>[];
      final effect = Effect(() {
        if (gate.value) seen.add(c.previousValue);
      });
      addTearDown(effect.dispose);

      c.value;
      source.value = 1;
      c.value;
      source.value = 2;
      c.value;
      expect(seen.last, 1);
    });

    test('an effect that first reads hasPreviousValue while the selector '
        'runs tracks the Computed', () {
      final source = Signal(0);
      final gate = Signal(false);
      final c = Computed(() {
        final value = source.value;
        if (value == 1) gate.value = true;
        return value;
      });
      var calls = 0;
      final effect = Effect(() {
        if (gate.value) {
          c.hasPreviousValue;
          calls++;
        }
      });
      addTearDown(effect.dispose);

      c.value;
      source.value = 1;
      c.value;
      final afterFirst = calls;
      source.value = 2;
      c.value;
      expect(calls, greaterThan(afterFirst));
    });

    test('an effect that disposes the Computed and reads previousValue while '
        'the selector runs does not subscribe to it', () {
      final source = Signal(0);
      final gate = Signal(false);
      late final Computed<int> c;
      c = Computed(() {
        final value = source.value;
        if (value == 1) gate.value = true;
        return value;
      });
      final effect = Effect(() {
        if (gate.value) {
          c.dispose();
          c.previousValue;
        }
      });
      addTearDown(effect.dispose);

      c.value;
      source.value = 1;
      c.value;
      expect(c.listenerCount, 0);
    });

    test(
      'a listener added while the comparator runs receives later changes',
      () {
        final source = Signal(0);
        late final Computed<int> c;
        final seen = <int>[];
        void listener() => seen.add(c.value);
        c = Computed(
          () => source.value,
          comparator: (a, b) {
            if (b == 1) c.addListener(listener);
            return a == b;
          },
        );
        addTearDown(() => c.removeListener(listener));

        expect(c.value, 0);
        source.value = 1;
        expect(c.value, 1);
        source.value = 2;
        expect(seen, [2]);
      },
    );

    test('run() that changes the value notifies the subscribers', () {
      var next = 0;
      final c = Computed(() => next);
      final seen = <int>[];
      final effect = Effect(() => seen.add(c.value));
      addTearDown(effect.dispose);

      next = 1;
      c.run();
      expect(seen, [0, 1]);
      c.run();
      expect(seen, [0, 1]);
    });

    test('run() with a throwing comparator notifies the subscribers', () {
      var next = 0;
      final error = ArgumentError('invalid comparison');
      final c = Computed(() => next, comparator: (_, _) => throw error);
      final seen = <int>[];
      final effect = Effect(() => seen.add(c.value));
      addTearDown(effect.dispose);

      next = 1;
      final reported = _reportedErrors(c.run);
      expect(reported.map((r) => r.$1), [same(error)]);
      expect(c.value, 1);
      expect(seen, [0, 1]);
    });

    test('an effect reruns when an observer of an equal update runs the '
        'Computed to a new value', () {
      final trigger = Signal(0);
      var sampled = 0;
      final c = Computed(() {
        trigger.value;
        return sampled;
      });
      final seen = <int>[];
      var once = true;
      final observer = _ReadingObserver((computed) {
        if (!once || !identical(computed, c)) return;
        once = false;
        sampled = 1;
        computed.run();
      });

      addTearDown(trigger.dispose);

      final effect = Effect(() => seen.add(c.value));
      addTearDown(effect.dispose);
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));

      // The outer evaluation returns 0 again, then the observer stores 1.
      trigger.value = 1;
      expect(c.value, 1);
      expect(seen, [0, 1]);
    });

    test('run() throws only its own error when an observer runs it again', () {
      var next = 0;
      final c = Computed(() {
        if (next == 2) throw StateError('nested');
        return next;
      });
      Object? nestedError;
      var once = true;
      final observer = _ReadingObserver((computed) {
        if (!once || !identical(computed, c)) return;
        once = false;
        next = 2;
        try {
          computed.run();
        } on Object catch (e) {
          nestedError = e;
        }
      });

      expect(c.value, 0);
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));

      next = 1;
      expect(c.run, returnsNormally);
      expect(nestedError, isA<SolidartCaughtException>());
    });

    test('run() does not notify again a change that an observer already '
        'stored with a nested run()', () {
      var next = 0;
      final c = Computed(() => next);
      final seen = <int>[];
      var once = true;
      final observer = _ReadingObserver((computed) {
        if (!once || !identical(computed, c)) return;
        once = false;
        next = 1;
        computed.run();
      });

      final effect = Effect(() => seen.add(c.value));
      addTearDown(effect.dispose);
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));

      // The outer run is equal. The nested run stores 1 and notifies.
      c.run();
      expect(seen, [0, 1]);
    });
  });
}
