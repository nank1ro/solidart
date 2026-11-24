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
