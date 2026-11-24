// ignore_for_file: cascade_invocations

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

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
  });
}
