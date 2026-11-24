import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('untrackedPreviousValue', () {
    test('is null with trackPreviousValue: false and observe agrees', () {
      final s = Signal(1, trackPreviousValue: false);
      addTearDown(s.dispose);
      final calls = <(int?, int)>[];
      final dispose = s.observe((prev, value) => calls.add((prev, value)));
      addTearDown(dispose);

      s.value = 2;

      expect(s.previousValue, isNull);
      expect(s.untrackedPreviousValue, isNull);
      expect(calls, [(null, 2)]);
    });

    test('ListSignal in-place add exposes the old list', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);
      final calls = <(List<int>?, List<int>)>[];
      final dispose = s.observe(
        (prev, value) => calls.add((prev, [...value])),
      );
      addTearDown(dispose);

      s.add(2);

      expect(s.untrackedPreviousValue, equals([1]));
      expect(calls, hasLength(1));
      expect(calls.single.$1, equals([1]));
      expect(calls.single.$2, equals([1, 2]));
    });

    test('ListSignal in-place add after value reassignment', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);

      s
        ..value = [1, 2]
        ..add(3);

      expect(s.untrackedPreviousValue, equals([1, 2]));
    });

    test('MapSignal in-place []= exposes the old map', () {
      final s = MapSignal({'a': 1});
      addTearDown(s.dispose);
      final calls = <(Map<String, int>?, Map<String, int>)>[];
      final dispose = s.observe(
        (prev, value) => calls.add((prev, {...value})),
      );
      addTearDown(dispose);

      s['b'] = 2;

      expect(calls, hasLength(1));
      expect(calls.single.$1, equals({'a': 1}));
      expect(calls.single.$2, equals({'a': 1, 'b': 2}));
    });

    test('SetSignal in-place add exposes the old set', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);

      s.add(2);

      expect(s.untrackedPreviousValue, equals({1}));
    });

    test('Resource untrackedPreviousState equals previousState', () async {
      final r = Resource(() async => 1);
      addTearDown(r.dispose);
      await r.untilReady();

      expect(r.previousState, isNotNull);
      expect(r.untrackedPreviousState, same(r.previousState));
    });

    test('GUARD: default tracking keeps the previous value', () {
      final s = Signal(1);
      addTearDown(s.dispose);
      final calls = <(int?, int)>[];
      final dispose = s.observe((prev, value) => calls.add((prev, value)));
      addTearDown(dispose);

      s.value = 2;

      expect(s.untrackedPreviousValue, 1);
      expect(calls, [(1, 2)]);
    });
  });
}
