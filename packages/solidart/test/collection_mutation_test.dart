import 'dart:collection';
import 'dart:math';

import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

/// Records what observers and effects see when `signal` changes.
///
/// `copy` snapshots the live collection, which later mutations change in
/// place.
class _Watch<T> {
  _Watch(Signal<T> signal, T Function(T value) copy) {
    final disposeObservation = signal.observe(
      (previous, value) => calls.add([previous, copy(value)]),
    );
    addTearDown(disposeObservation);
    final effect = Effect(() {
      signal.value;
      _effectRuns++;
    });
    addTearDown(effect.dispose);
  }

  /// The `[previous, value]` pairs passed to the observer.
  ///
  /// Lists, not records, so that `equals` compares them deeply.
  final calls = <List<Object?>>[];

  var _effectRuns = 0;

  /// How many times the effect ran again after its first run.
  int get effectReruns => _effectRuns - 1;
}

/// Equal to every other `_Same`: only `identical` tells two of them apart.
class _Same {
  _Same(this.order);

  final int order;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is _Same;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}

/// Yields [elements], then throws a [StateError].
Iterable<T> _throwAfter<T>(List<T> elements) sync* {
  yield* elements;
  throw StateError('interrupted');
}

void main() {
  group('ListSignal', () {
    _Watch<List<T>> watch<T>(ListSignal<T> s) {
      addTearDown(s.dispose);
      return _Watch<List<T>>(s, List<T>.of);
    }

    test('retainWhere notifies once with the old list', () {
      final s = ListSignal([1, 2, 3]);
      final w = watch(s);

      s.retainWhere((x) => x > 1);

      expect(s.untrackedValue, [2, 3]);
      expect(w.calls, [
        [
          [1, 2, 3],
          [2, 3],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('retainWhere that keeps everything does not notify', () {
      final s = ListSignal([1, 2, 3]);
      final w = watch(s);

      s.retainWhere((x) => x > 0);

      expect(s.untrackedValue, [1, 2, 3]);
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('shrinking length records the old list', () {
      final s = ListSignal([1, 2]);
      final w = watch(s);

      s.length = 1;

      expect(s.untrackedValue, [1]);
      expect(w.calls, [
        [
          [1, 2],
          [1],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('growing length records the old list', () {
      final s = ListSignal<int?>([1]);
      final w = watch(s);

      s.length = 2;

      expect(s.untrackedValue, [1, null]);
      expect(w.calls, [
        [
          [1],
          [1, null],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('sort notifies once with the old list', () {
      final s = ListSignal([3, 1, 2]);
      final w = watch(s);

      s.sort();

      expect(s.untrackedValue, [1, 2, 3]);
      expect(w.calls, [
        [
          [3, 1, 2],
          [1, 2, 3],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('sort of a sorted list does not notify', () {
      final s = ListSignal([1, 2, 3]);
      final w = watch(s);

      s.sort();

      expect(s.untrackedValue, [1, 2, 3]);
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('shuffle that changes the order notifies once', () {
      final shuffled = [1, 2, 3, 4, 5]..shuffle(Random(2));
      expect(shuffled, isNot([1, 2, 3, 4, 5]));
      final s = ListSignal([1, 2, 3, 4, 5]);
      final w = watch(s);

      s.shuffle(Random(2));

      expect(s.untrackedValue, shuffled);
      expect(w.calls, [
        [
          [1, 2, 3, 4, 5],
          shuffled,
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('shuffle that keeps the order does not notify', () {
      // Random(1) shuffles a 5-element list back into the same order.
      expect([1, 2, 3, 4, 5]..shuffle(Random(1)), [1, 2, 3, 4, 5]);
      final s = ListSignal([1, 2, 3, 4, 5]);
      final w = watch(s);

      s.shuffle(Random(1));

      expect(s.untrackedValue, [1, 2, 3, 4, 5]);
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('remove of an object of another type returns false', () {
      final s = ListSignal([1, 2]);
      final w = watch(s);

      // An object that is not an element type, as `remove` accepts.
      const Object other = 'a';
      expect(s.remove(other), isFalse);

      expect(s.untrackedValue, [1, 2]);
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
    });

    final failingMutations = <String, void Function(ListSignal<int>)>{
      'insert': (s) => s.insert(5, 0),
      'insertAll': (s) => s.insertAll(5, [0]),
      'removeAt': (s) => s.removeAt(5),
      'removeRange': (s) => s.removeRange(0, 5),
      'fillRange': (s) => s.fillRange(0, 5, 0),
      'replaceRange': (s) => s.replaceRange(0, 5, [0]),
      'setAll': (s) => s.setAll(5, [0]),
      'setRange': (s) => s.setRange(0, 5, [0]),
    };
    for (final MapEntry(key: name, value: mutate) in failingMutations.entries) {
      test('$name that throws does not touch history', () {
        final s = ListSignal([1, 2]);
        final w = watch(s);

        expect(() => mutate(s), throwsA(isA<Error>()));

        expect(s.untrackedValue, [1, 2]);
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedHasPreviousValue, isFalse);
      });
    }

    test('removeLast on an empty list does not touch history', () {
      final s = ListSignal<int>([]);
      final w = watch(s);

      expect(s.removeLast, throwsA(isA<Error>()));

      expect(s.untrackedValue, isEmpty);
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('a no-op write in a batch keeps the previous value', () {
      final s = ListSignal([1]);
      final w = watch(s);

      batch(() {
        s
          ..value = [2]
          ..fillRange(0, 1, 2);
      });

      expect(w.calls, [
        [
          [1],
          [2],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    final identicalWrites = <String, void Function(ListSignal<int>)>{
      'fillRange': (s) => s.fillRange(0, 1, 1),
      'setAll': (s) => s.setAll(0, [1, 2]),
      'setRange': (s) => s.setRange(0, 2, [1, 2]),
      'replaceRange': (s) => s.replaceRange(0, 2, [1, 2]),
    };
    for (final MapEntry(key: name, value: write) in identicalWrites.entries) {
      test('$name that writes the same elements does not notify', () {
        final s = ListSignal([1, 2]);
        final w = watch(s);

        write(s);

        expect(s.untrackedValue, [1, 2]);
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedHasPreviousValue, isFalse);
      });
    }

    test('writing an equal but distinct element notifies once', () {
      final a = _Same(0);
      final b = _Same(1);
      final s = ListSignal([a]);
      final w = watch(s);

      s[0] = b;

      expect(s.untrackedValue.single, same(b));
      expect(w.calls, hasLength(1));
      final [previous as List<_Same>, value as List<_Same>] = w.calls.single;
      expect(previous.single, same(a));
      expect(value.single, same(b));
      expect(w.effectReruns, 1);
    });

    test('sort that reorders equal but distinct elements notifies once', () {
      final s = ListSignal([_Same(2), _Same(0), _Same(1)]);
      final w = watch(s);

      s.sort((a, b) => a.order.compareTo(b.order));

      expect(s.untrackedValue.map((e) => e.order), [0, 1, 2]);
      expect(w.calls, hasLength(1));
      final [previous as List<_Same>, _] = w.calls.single;
      expect(previous.map((e) => e.order), [2, 0, 1]);
      expect(w.effectReruns, 1);
    });

    test('shuffle that reorders equal but distinct elements notifies once', () {
      final orders = [0, 1, 2, 3, 4];
      final shuffled = List.of(orders)..shuffle(Random(2));
      expect(shuffled, isNot(orders));
      final s = ListSignal([for (final order in orders) _Same(order)]);
      final w = watch(s);

      s.shuffle(Random(2));

      expect(s.untrackedValue.map((e) => e.order), shuffled);
      expect(w.calls, hasLength(1));
      final [previous as List<_Same>, _] = w.calls.single;
      expect(previous.map((e) => e.order), orders);
      expect(w.effectReruns, 1);
    });

    final rejectedMutations = <String, void Function(ListSignal<int>)>{
      'add': (s) => s.add(4),
      'sort': (s) => s.sort(),
      'shuffle': (s) => s.shuffle(Random(2)),
    };
    for (final MapEntry(key: name, value: mutate)
        in rejectedMutations.entries) {
      test('$name on an unmodifiable list throws and changes nothing', () {
        final s = ListSignal([0])..value = List.unmodifiable([3, 1, 2]);
        final previous = s.untrackedPreviousValue;
        final w = watch(s);

        expect(() => mutate(s), throwsUnsupportedError);

        expect(s.untrackedValue, [3, 1, 2]);
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedPreviousValue, same(previous));
      });
    }

    test('addAll from an iterable that throws partway notifies once', () {
      final s = ListSignal([1]);
      final w = watch(s);

      expect(() => s.addAll(_throwAfter([2])), throwsStateError);

      expect(s.untrackedValue, [1, 2]);
      expect(w.calls, [
        [
          [1],
          [1, 2],
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('a mutation inside an effect does not subscribe the effect', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        s.remove(0);
      });
      addTearDown(effect.dispose);

      s.add(2);

      expect(runs, 1);
    });
  });

  group('MapSignal', () {
    _Watch<Map<K, V>> watch<K, V>(MapSignal<K, V> s) {
      addTearDown(s.dispose);
      return _Watch<Map<K, V>>(s, Map<K, V>.of);
    }

    test('update of an existing key notifies once with the old map', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);

      expect(s.update('a', (v) => v + 1), 2);

      expect(s.untrackedValue, {'a': 2, 'b': 2});
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          {'a': 2, 'b': 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('update with ifAbsent notifies once with the old map', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      expect(s.update('b', (v) => v + 1, ifAbsent: () => 5), 5);

      expect(s.untrackedValue, {'a': 1, 'b': 5});
      expect(w.calls, [
        [
          {'a': 1},
          {'a': 1, 'b': 5},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('update to the same value does not notify', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      expect(s.update('a', (v) => v), 1);

      expect(s.untrackedValue, {'a': 1});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('update with an ifAbsent that throws does not touch history', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      expect(
        () => s.update('b', (v) => v, ifAbsent: () => throw StateError('x')),
        throwsStateError,
      );

      expect(s.untrackedValue, {'a': 1});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('updateAll keeps unchanged values (nullable values)', () {
      final s = MapSignal<String, int?>({'a': 1, 'b': 2});
      final w = watch(s);

      s.updateAll((k, v) => k == 'a' ? 2 : v);

      expect(s.untrackedValue, {'a': 2, 'b': 2});
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          {'a': 2, 'b': 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('updateAll keeps unchanged values (non-nullable values)', () {
      final s = MapSignal<String, int>({'a': 1, 'b': 2});
      final w = watch(s);

      s.updateAll((k, v) => k == 'a' ? 2 : v);

      expect(s.untrackedValue, {'a': 2, 'b': 2});
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          {'a': 2, 'b': 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('updateAll that changes nothing does not notify', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);

      s.updateAll((k, v) => v);

      expect(s.untrackedValue, {'a': 1, 'b': 2});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('updateAll whose callback throws leaves the map unchanged', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);

      expect(
        () => s.updateAll((k, v) => k == 'b' ? throw StateError('x') : v + 1),
        throwsStateError,
      );

      expect(s.untrackedValue, {'a': 1, 'b': 2});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('putIfAbsent with an ifAbsent that throws does not touch history', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      expect(
        () => s.putIfAbsent('b', () => throw StateError('x')),
        throwsStateError,
      );

      expect(s.untrackedValue, {'a': 1});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('a no-op write in a batch keeps the previous value', () {
      final s = MapSignal({'k': 1});
      final w = watch(s);

      batch(() {
        s
          ..value = {'k': 2}
          ..addAll({'k': 2});
      });

      expect(w.calls, [
        [
          {'k': 1},
          {'k': 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    final identicalWrites = <String, void Function(MapSignal<String, int>)>{
      'addAll': (s) => s.addAll({'a': 1}),
      'addEntries': (s) => s.addEntries([const MapEntry('a', 1)]),
    };
    for (final MapEntry(key: name, value: write) in identicalWrites.entries) {
      test('$name that writes the same entries does not notify', () {
        final s = MapSignal({'a': 1});
        final w = watch(s);

        write(s);

        expect(s.untrackedValue, {'a': 1});
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedHasPreviousValue, isFalse);
      });
    }

    test('writing an equal but distinct value notifies once', () {
      final a = _Same(0);
      final b = _Same(1);
      final s = MapSignal({'k': a});
      final w = watch(s);

      s['k'] = b;

      expect(s.untrackedValue['k'], same(b));
      expect(w.calls, hasLength(1));
      final [previous as Map<String, _Same>, _] = w.calls.single;
      expect(previous['k'], same(a));
      expect(w.effectReruns, 1);
    });

    final rejectedMutations = <String, void Function(MapSignal<String, int>)>{
      'update': (s) => s.update('a', (v) => v + 1),
      'update with ifAbsent': (s) => s.update('b', (v) => v, ifAbsent: () => 2),
      'putIfAbsent': (s) => s.putIfAbsent('b', () => 2),
      'updateAll': (s) => s.updateAll((k, v) => v + 1),
      '[]=': (s) => s['b'] = 2,
      'remove': (s) => s.remove('a'),
    };
    for (final MapEntry(key: name, value: mutate)
        in rejectedMutations.entries) {
      test('$name on an unmodifiable map throws and changes nothing', () {
        final s = MapSignal(Map<String, int>.unmodifiable({'a': 1}));
        final w = watch(s);

        expect(() => mutate(s), throwsUnsupportedError);

        expect(s.untrackedValue, {'a': 1});
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedHasPreviousValue, isFalse);
      });
    }

    test('a mutation inside an effect does not subscribe the effect', () {
      final s = MapSignal({'a': 1});
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        s.remove('missing');
      });
      addTearDown(effect.dispose);

      s['b'] = 2;

      expect(runs, 1);
    });
  });

  group('SetSignal', () {
    _Watch<Set<E>> watch<E>(SetSignal<E> s) {
      addTearDown(s.dispose);
      return _Watch<Set<E>>(s, (value) => value.toSet());
    }

    test('retainWhere notifies once with the old set', () {
      final s = SetSignal({1, 2, 3});
      final w = watch(s);

      s.retainWhere((x) => x > 1);

      expect(s.untrackedValue, {2, 3});
      expect(w.calls, [
        [
          {1, 2, 3},
          {2, 3},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('retainWhere that keeps everything does not notify', () {
      final s = SetSignal({1, 2, 3});
      final w = watch(s);

      s.retainWhere((x) => x > 0);

      expect(s.untrackedValue, {1, 2, 3});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('remove uses the equality of an identity set', () {
      final a = DateTime.fromMillisecondsSinceEpoch(0);
      final b = DateTime.fromMillisecondsSinceEpoch(0);
      expect(a, b);
      expect(identical(a, b), isFalse);
      final s = SetSignal(Set<DateTime>.identity()..add(a));
      final w = watch(s);

      expect(s.remove(b), isFalse);

      expect(s.untrackedValue, hasLength(1));
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);

      expect(s.remove(a), isTrue);

      expect(s.untrackedValue, isEmpty);
      expect(w.calls, hasLength(1));
      final [previous as Set<DateTime>, value as Set<DateTime>] =
          w.calls.single;
      expect(identical(previous.single, a), isTrue);
      expect(value, isEmpty);
      expect(w.effectReruns, 1);
    });

    test('remove of an object of another type returns false', () {
      final s = SetSignal({1, 2});
      final w = watch(s);

      // An object that is not an element type, as `remove` accepts.
      const Object other = 'a';
      expect(s.remove(other), isFalse);

      expect(s.untrackedValue, {1, 2});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
    });

    test('addAll notifies once with the old set', () {
      final s = SetSignal({1});
      final w = watch(s);

      s.addAll({1, 2, 3});

      expect(s.untrackedValue, {1, 2, 3});
      expect(w.calls, [
        [
          {1},
          {1, 2, 3},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('addAll of elements already present does not notify', () {
      final s = SetSignal({1, 2});
      final w = watch(s);

      s.addAll({1, 2});

      expect(s.untrackedValue, {1, 2});
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.untrackedHasPreviousValue, isFalse);
    });

    test('addAll from an iterable that throws partway notifies once', () {
      final s = SetSignal({1});
      final w = watch(s);

      expect(() => s.addAll(_throwAfter([2])), throwsStateError);

      expect(s.untrackedValue, {1, 2});
      expect(w.calls, [
        [
          {1},
          {1, 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('removeAll from an iterable that throws partway notifies once', () {
      final s = SetSignal({1, 2});
      final w = watch(s);

      expect(() => s.removeAll(_throwAfter([1])), throwsStateError);

      expect(s.untrackedValue, {2});
      expect(w.calls, [
        [
          {1, 2},
          {2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('removing an absent equal object from an identity set in a batch '
        'keeps the previous value', () {
      final a = DateTime.fromMillisecondsSinceEpoch(0);
      final b = DateTime.fromMillisecondsSinceEpoch(0);
      final s = SetSignal({DateTime.fromMillisecondsSinceEpoch(1)});
      final w = watch(s);

      batch(() {
        s.value = Set<DateTime>.identity()..add(a);
        expect(s.remove(b), isFalse);
      });

      expect(s.untrackedValue.single, same(a));
      expect(w.calls, hasLength(1));
      final [previous as Set<DateTime>, _] = w.calls.single;
      expect(previous, {DateTime.fromMillisecondsSinceEpoch(1)});
      expect(w.effectReruns, 1);
    });

    test('the previous value keeps the equality of an identity set', () {
      final a = DateTime.fromMillisecondsSinceEpoch(0);
      final b = DateTime.fromMillisecondsSinceEpoch(0);
      final s = SetSignal(Set<DateTime>.identity()..add(a));
      addTearDown(s.dispose);

      expect(s.add(b), isTrue);

      final previous = s.untrackedPreviousValue!;
      expect(previous.single, same(a));
      expect(previous.contains(b), isFalse);
    });

    test('the previous value keeps the equality of a custom set', () {
      final s = SetSignal(
        LinkedHashSet<String>(
          equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
          hashCode: (e) => e.toLowerCase().hashCode,
        )..add('A'),
      );
      addTearDown(s.dispose);

      expect(s.add('b'), isTrue);

      final previous = s.untrackedPreviousValue!;
      expect(previous, {'A'});
      expect(previous.contains('a'), isTrue);
    });

    test('a mutation inside an effect does not subscribe the effect', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        s.remove(0);
      });
      addTearDown(effect.dispose);

      s.add(2);

      expect(runs, 1);
    });
  });
}
