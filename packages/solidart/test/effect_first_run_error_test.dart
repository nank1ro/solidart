import 'dart:async';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('Effect whose first run throws', () {
    test('without onError is disposed and rethrows', () {
      final s = Signal(0);
      final seen = <int>[];
      addTearDown(s.dispose);

      expect(
        () => Effect(() {
          if (s.value == 0) throw StateError('x');
          seen.add(s.value);
        }),
        throwsA(isA<StateError>()),
      );

      s.value = 1;
      expect(seen, isEmpty);
    });

    test('rethrows the original error when disposal also throws', () {
      final setupError = StateError('setup');
      final reported = <Object>[];
      final s = Signal(0, autoDispose: true)
        ..onDispose(() => throw StateError('cleanup'));

      Object? thrown;
      StackTrace? thrownStack;
      StackTrace? setupStack;
      runZonedGuarded(() {
        try {
          Effect(() {
            s.value;
            try {
              throw setupError;
            } catch (_, st) {
              setupStack = st;
              rethrow;
            }
          });
        } catch (e, st) {
          thrown = e;
          thrownStack = st;
        }
      }, (error, _) => reported.add(error));

      expect(thrown, same(setupError));
      expect(setupStack, isNotNull);
      expect(thrownStack.toString(), setupStack.toString());
      expect(reported, hasLength(1));
      expect(reported.single, isA<StateError>());
      expect((reported.single as StateError).message, 'cleanup');
    });

    test('with onError stays alive', () {
      final s = Signal(0);
      final seen = <int>[];
      final errors = <Object>[];
      addTearDown(s.dispose);

      Effect(
        () {
          if (s.value == 0) throw StateError('x');
          seen.add(s.value);
        },
        onError: errors.add,
      );

      expect(errors, hasLength(1));
      s.value = 1;
      expect(seen, [1]);
    });

    test('observe() leaves no subscriber', () {
      final s = Signal(0);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });
      addTearDown(s.dispose);
      addTearDown(c.dispose);

      expect(() => c.observe((_, _) {}), throwsA(anything));
      expect(c.listenerCount, 0);
    });

    test('addListener() leaves no listener', () {
      final s = Signal(0);
      final c = Computed(() {
        if (s.value == 0) throw StateError('zero');
        return s.value;
      });
      addTearDown(s.dispose);
      addTearDown(c.dispose);

      expect(() => c.addListener(() {}), throwsA(anything));
      expect(c.listenerCount, 0);
    });
  });
}
