import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('throwing effect inside batch()', () {
    test('does not drop updates queued for other effects', () {
      final a = Signal(0);
      final b = Signal(0);
      final seen = <int>[];

      Effect(() {
        if (a.value == 1) throw StateError('bad');
      });
      Effect(() => seen.add(b.value));

      addTearDown(a.dispose);
      addTearDown(b.dispose);

      // The first effect throws while the batch flushes, but the second one
      // (which does not depend on `a`) must still observe the update to `b`.
      expect(
        () => batch(() {
          a.value = 1;
          b.value = 1;
        }),
        throwsA(isA<StateError>()),
      );

      expect(seen, [0, 1]);
      expect(b.value, 1);
    });

    test('rethrows the first error after running every queued effect', () {
      final s = Signal(0);
      final ran = <String>[];

      Effect(() {
        s.value;
        ran.add('first');
        if (s.value == 1) throw StateError('first-error');
      });
      Effect(() {
        s.value;
        ran.add('second');
        if (s.value == 1) throw StateError('second-error');
      });

      addTearDown(s.dispose);
      ran.clear();

      Object? thrown;
      try {
        batch(() => s.value = 1);
      } catch (e) {
        thrown = e;
      }

      // Both effects ran despite throwing...
      expect(ran, containsAll(<String>['first', 'second']));
      // ...and only the first error surfaced.
      expect(thrown, isA<StateError>());
      expect((thrown! as StateError).message, 'first-error');
    });

    test('a throwing effect with onError does not abort the batch flush', () {
      final a = Signal(0);
      final b = Signal(0);
      final seen = <int>[];
      final errors = <Object>[];

      Effect(
        () {
          if (a.value == 1) throw StateError('bad');
        },
        onError: errors.add,
      );
      Effect(() => seen.add(b.value));

      addTearDown(a.dispose);
      addTearDown(b.dispose);

      // onError swallows the error, so the batch completes normally and the
      // second effect still sees the update.
      batch(() {
        a.value = 1;
        b.value = 1;
      });

      expect(errors.single, isA<SolidartCaughtException>());
      expect(seen, [0, 1]);
    });

    test('surfaces the error for a throwing effect outside a batch', () {
      final s = Signal(0);

      Effect(() {
        if (s.value == 1) throw StateError('bad');
      });

      addTearDown(s.dispose);

      expect(() => s.value = 1, throwsA(isA<StateError>()));
    });
  });
}
