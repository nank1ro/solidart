import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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

/// Runs [body] in a zone. Returns the error that [body] throws, with its
/// stack trace, and the errors that are reported to the zone.
({Object? error, StackTrace? stackTrace, List<Object> reported}) _guarded(
  void Function() body,
) {
  Object? error;
  StackTrace? stackTrace;
  final reported = <Object>[];
  runZonedGuarded(() {
    try {
      body();
    } catch (e, s) {
      error = e;
      stackTrace = s;
    }
  }, (e, _) => reported.add(e));
  return (error: error, stackTrace: stackTrace, reported: reported);
}

/// Expects that [mutate] throws the `interrupted` error of [_throwAfter],
/// with its stack trace, and that the error of the effect that reacts to
/// the partial change goes to the zone.
void _expectMutationErrorWins(void Function() mutate) {
  final result = _guarded(mutate);

  expect(
    result.error,
    isA<StateError>().having((e) => e.message, 'message', 'interrupted'),
  );
  expect(result.stackTrace.toString(), contains('_throwAfter'));
  expect(result.reported, [
    isA<StateError>().having((e) => e.message, 'message', 'effect'),
  ]);
}

/// A list of zeros that counts how many times an element is read.
class _CountingList extends ListBase<int> {
  _CountingList(int length) : _elements = List.filled(length, 0);

  final List<int> _elements;

  int reads = 0;

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) => _elements.length = newLength;

  @override
  int operator [](int index) {
    reads++;
    return _elements[index];
  }

  @override
  void operator []=(int index, int value) => _elements[index] = value;
}

class _CountingMap extends DelegatingMap<int, int> {
  _CountingMap() : super({for (var i = 0; i < 100; i++) i: i});
  int scans = 0;
  int reads = 0;

  @override
  int? operator [](Object? key) {
    reads++;
    return super[key];
  }

  @override
  Iterable<MapEntry<int, int>> get entries {
    scans++;
    return super.entries;
  }

  @override
  Iterable<int> get keys {
    scans++;
    return super.keys;
  }

  @override
  void forEach(void Function(int, int) action) {
    scans++;
    super.forEach(action);
  }
}

class _CountingSet extends DelegatingSet<int> {
  _CountingSet() : super({for (var i = 0; i < 100; i++) i});
  int scans = 0;

  @override
  List<int> toList({bool growable = true}) {
    scans++;
    return super.toList(growable: growable);
  }

  @override
  Iterator<int> get iterator {
    scans++;
    return super.iterator;
  }
}

/// A list whose length cannot change. `ListBase.removeAt` moves the
/// elements first, so it changes the list and then throws.
class _FixedLengthList extends ListBase<int> {
  _FixedLengthList(this._elements);

  final List<int> _elements;

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) => throw UnsupportedError('fixed length');

  @override
  int operator [](int index) => _elements[index];

  @override
  void operator []=(int index, int value) => _elements[index] = value;
}

void main() {
  group('point mutation cost', () {
    test('list slot write without history reads only the slot', () {
      final backing = _CountingList(100);
      final list = ListSignal<int>([], trackPreviousValue: false)
        ..value = backing;
      addTearDown(list.dispose);
      backing.reads = 0;
      list[50] = 1;
      expect(backing.reads, lessThanOrEqualTo(2));
    });

    for (final history in [false, true]) {
      final writes = <String, void Function(MapSignal<int, int>)>{
        'update existing key': (s) => s[50] = -1,
        'insert key': (s) => s[100] = -1,
        'remove key': (s) => s.remove(50),
      };
      for (final MapEntry(key: name, value: write) in writes.entries) {
        test('$name with history $history', () {
          final backing = _CountingMap();
          final s = MapSignal<int, int>({}, trackPreviousValue: history)
            ..value = backing;
          addTearDown(s.dispose);
          backing
            ..scans = 0
            ..reads = 0;
          write(s);
          expect(backing.scans, lessThanOrEqualTo(history ? 1 : 0));
          expect(backing.reads, lessThanOrEqualTo(2));
        });
      }
    }
    final setWrites = <String, void Function(SetSignal<int>)>{
      'add': (s) => s.add(100),
      'remove': (s) => s.remove(50),
    };
    for (final MapEntry(key: name, value: write) in setWrites.entries) {
      test('set $name without history', () {
        final backing = _CountingSet();
        final s = SetSignal<int>({}, trackPreviousValue: false)
          ..value = backing;
        addTearDown(s.dispose);
        backing.scans = 0;
        write(s);
        expect(backing.scans, 0);
      });
    }
  });

  group('ListSignal', () {
    _Watch<List<T>> watch<T>(ListSignal<T> s) {
      addTearDown(s.dispose);
      return _Watch<List<T>>(s, List<T>.of);
    }

    test('a callback that assigns a value keeps the old list as previous', () {
      final s = ListSignal([1, 2]);
      final w = watch(s);

      var assigned = false;
      s.removeWhere((e) {
        if (!assigned) s.value = [9];
        assigned = true;
        return e == 1;
      });

      expect(s.untrackedValue, [9]);
      expect(s.previousValue, [1, 2]);
      expect(w.calls.single[0], [1, 2]);
    });

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

    test('sort without history notifies only for the first reorder', () {
      final s = ListSignal([2, 1], trackPreviousValue: false);
      final w = watch(s);

      s
        ..sort()
        ..sort();

      expect(w.effectReruns, 1);
      expect(s.untrackedValue, [1, 2]);
      expect(s.untrackedPreviousValue, isNull);
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
      final s = ListSignal([1, 2, 3, 4, 5]);
      final w = watch(s);

      s.shuffle(_NoSwapRandom());

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
      'empty removeRange': (s) => s.removeRange(5, 5),
      'empty fillRange': (s) => s.fillRange(5, 5, 0),
      'empty replaceRange': (s) => s.replaceRange(5, 5, []),
      'empty setAll': (s) => s.setAll(5, []),
      'empty setRange': (s) => s.setRange(5, 5, []),
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
      '[]= of the same element': (s) => s[0] = 3,
      'first= of the same element': (s) => s.first = 3,
      'last= of the same element': (s) => s.last = 2,
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
    test('a partial change keeps its error when an effect also throws', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.length == 2) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      _expectMutationErrorWins(() => s.addAll(_throwAfter([2])));

      expect(s.untrackedValue, [1, 2]);
    });

    final oneIndexWrites = <String, void Function(ListSignal<int>)>{
      '[]=': (s) => s[1] = 0,
      'first=': (s) => s.first = 0,
      'last=': (s) => s.last = 0,
    };
    for (final MapEntry(key: name, value: write) in oneIndexWrites.entries) {
      test('$name of the same element reads only that element', () {
        int readsFor(int length) {
          final backing = _CountingList(length);
          final s = ListSignal<int>([])..value = backing;
          addTearDown(s.dispose);
          backing.reads = 0;
          write(s);
          return backing.reads;
        }

        expect(readsFor(100), readsFor(2));
      });
    }

    // Each read of a `Float32x4List` element creates a new object, so a
    // comparison by identity sees every element as changed.
    final emptyRanges = <String, void Function(ListSignal<Float32x4>)>{
      'fillRange': (s) => s.fillRange(0, 0, Float32x4.zero()),
      'setAll': (s) => s.setAll(0, const []),
      'setRange': (s) => s.setRange(0, 0, const []),
    };
    for (final MapEntry(key: name, value: write) in emptyRanges.entries) {
      test('$name of an empty range does not notify', () {
        final s = ListSignal<Float32x4>([])..value = Float32x4List(1);
        final previous = s.untrackedPreviousValue;
        final w = watch(s);

        write(s);

        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
        expect(s.untrackedPreviousValue, same(previous));
      });
    }

    final rejectedEmptyRanges = <String, void Function(ListSignal<Float32x4>)>{
      'removeRange': (s) => s.removeRange(0, 0),
      'replaceRange': (s) => s.replaceRange(0, 0, const []),
    };
    for (final MapEntry(key: name, value: mutate)
        in rejectedEmptyRanges.entries) {
      test(
        '$name of an empty range on a fixed-length list does not notify',
        () {
          final s = ListSignal<Float32x4>([])..value = Float32x4List(1);
          final previous = s.untrackedPreviousValue;
          final w = watch(s);

          expect(() => mutate(s), throwsUnsupportedError);

          expect(w.calls, isEmpty);
          expect(w.effectReruns, 0);
          expect(s.untrackedPreviousValue, same(previous));
        },
      );
    }

    // Without history, these mutations do not read the elements, so they
    // work on a cast list that throws a TypeError when it reads 'unread'.
    final resizes = <String, void Function(ListSignal<int>)>{
      'add': (s) => s.add(3),
      'insert': (s) => s.insert(0, 3),
      'removeAt': (s) => s.removeAt(0),
      'removeLast': (s) => s.removeLast(),
      'clear': (s) => s.clear(),
      'shrinking length': (s) => s.length = 1,
    };
    for (final MapEntry(key: name, value: mutate) in resizes.entries) {
      test('$name of a cast list without history notifies once', () {
        final s = ListSignal<int>([], trackPreviousValue: false)
          ..value = <Object>[1, 'unread', 2].cast<int>();
        addTearDown(s.dispose);
        var runs = 0;
        final effect = Effect(() {
          s.value;
          runs++;
        });
        addTearDown(effect.dispose);

        mutate(s);

        expect(runs, 2);
      });
    }

    test('a resize that keeps the length without history does not notify', () {
      final s = ListSignal([1], trackPreviousValue: false);
      final w = watch(s);

      s.length = 1;

      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
    });

    test('a removeAt that moves elements and then throws notifies once', () {
      final s = ListSignal<int>([])..value = _FixedLengthList([1, 2, 3]);
      final w = watch(s);

      expect(() => s.removeAt(0), throwsUnsupportedError);

      expect(s.untrackedValue, [2, 3, 3]);
      expect(w.calls, [
        [
          [1, 2, 3],
          [2, 3, 3],
        ],
      ]);
      expect(w.effectReruns, 1);
    });
  });

  group('MapSignal', () {
    _Watch<Map<K, V>> watch<K, V>(MapSignal<K, V> s) {
      addTearDown(s.dispose);
      return _Watch<Map<K, V>>(s, Map<K, V>.of);
    }

    test('a callback that assigns a value keeps the old map as previous', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      s.update('a', (v) {
        s.value = {'x': 9};
        return 2;
      });

      expect(s.untrackedValue, {'x': 9});
      expect(s.previousValue, {'a': 1});
      expect(w.calls.single[0], {'a': 1});
    });

    test('history off: keys with a throwing hashCode do not block the '
        'notification', () {
      final s = MapSignal<Object, int>(
        Map<Object, int>.identity()
          ..[_ThrowingHash()] = 0
          ..['a'] = 1,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      final result = s.update('a', (_) => 2);

      expect([result, s.untrackedValue['a'], runs - 1], [2, 2, 1]);
    });

    test('history on: a failed history copy prevents the mutation', () {
      final s = MapSignal<Object, int>(
        Map<Object, int>.identity()
          ..[_ThrowingHash()] = 0
          ..['a'] = 1,
      );
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      expect(s.clear, throwsUnsupportedError);

      expect(s.untrackedValue.length, 2);
      expect(s.untrackedValue.values, [0, 1]);
      expect(runs, 1);
    });

    test(
      'bulk changes keep both identities when the history map merges keys',
      () {
        final a = _Same(1);
        final b = _Same(2);
        final backing = Map<_Same, int>.identity()
          ..[a] = 1
          ..[b] = 2;
        final s = MapSignal(backing);
        addTearDown(s.dispose);
        var runs = 0;
        final effect = Effect(() {
          s.value;
          runs++;
        });
        addTearDown(effect.dispose);

        s.updateAll((key, value) => value);
        expect(runs, 1);
        s.update(a, (_) => 3);
        expect(runs, 2);
        expect(s.untrackedPreviousValue!.length, 1);
        expect(s.untrackedPreviousValue![a], 2);
      },
    );

    test('history off: an assignment inside a mutation does not copy the '
        'map', () {
      final s = MapSignal<Object, int>(
        Map<Object, int>.identity()
          ..[_ThrowingHash()] = 0
          ..['a'] = 1,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      s.update('a', (_) {
        s.value = {'x': 9};
        return 2;
      });

      expect(s.untrackedValue, {'x': 9});
      expect(runs, 2);
    });

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

    test('writing null notifies only when it adds a key', () {
      final s = MapSignal<String, int?>({});
      final w = watch(s);

      s
        ..['a'] = null
        ..['a'] = null;

      expect(w.effectReruns, 1);
      expect(s.untrackedValue, {'a': null});
      expect(s.untrackedPreviousValue, isEmpty);
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

    test('update without history whose callback writes another key '
        'and returns a new value notifies once', () {
      final s = MapSignal({'a': 1, 'b': 2}, trackPreviousValue: false);
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      s.update('a', (v) {
        s['b'] = 3;
        return v + 1;
      });

      expect(s.untrackedValue, {'a': 2, 'b': 3});
      expect(runs, 2);
    });

    test('updateAll whose callback throws behaves like a plain map', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);
      final reference = {'a': 1, 'b': 2};
      int callback(String k, int v) => k == 'b' ? throw StateError('x') : v + 1;

      expect(() => reference.updateAll(callback), throwsStateError);
      expect(() => s.updateAll(callback), throwsStateError);

      expect(s.untrackedValue, reference);
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          reference,
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('updateAll lets a later callback restore an earlier key', () {
      final s = MapSignal({'a': 1, 'b': 1});
      final reference = {'a': 1, 'b': 1};
      for (final map in [reference, s]) {
        map.updateAll((k, v) {
          if (k == 'b') map['a'] = 1;
          return k == 'a' ? 5 : v;
        });
      }

      expect(s.untrackedValue, reference);
    });

    test('updateAll lets the return value win over a write to its key', () {
      final s = MapSignal({'a': 1, 'b': 1});
      final reference = {'a': 1, 'b': 1};
      for (final map in [reference, s]) {
        map.updateAll((k, v) {
          if (k == 'a') map['a'] = 7;
          return k == 'a' ? 2 : v;
        });
      }

      expect(s.untrackedValue, reference);
      expect(s.untrackedValue['a'], 2);
    });

    test('updateAll of an empty unmodifiable map throws like a plain map', () {
      final s = MapSignal<String, int>(Map.unmodifiable(<String, int>{}));
      addTearDown(s.dispose);

      expect(
        () => Map<String, int>.unmodifiable(<String, int>{}).updateAll(
          (k, v) => v,
        ),
        throwsUnsupportedError,
      );
      expect(() => s.updateAll((k, v) => v), throwsUnsupportedError);
    });

    test('updateAll keeps a callback write to a key it already visited', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final reference = {'a': 1, 'b': 2};
      for (final map in [reference, s]) {
        map.updateAll((k, v) {
          if (k == 'b') map['a'] = 7;
          return v;
        });
      }

      expect(s.untrackedValue, reference);
      expect(s.untrackedValue['a'], 7);
    });

    test('updateAll keeps a callback write over a changed visited key', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final reference = {'a': 1, 'b': 2};
      for (final map in [reference, s]) {
        map.updateAll((k, v) {
          if (k == 'b') map['a'] = 7;
          return k == 'a' ? 5 : v;
        });
      }

      expect(s.untrackedValue, reference);
      expect(s.untrackedValue['a'], 7);
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
      '[]= of the same value': (s) => s['a'] = 1,
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
    test('update whose callback assigns a new map notifies once', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      s.update('a', (v) {
        s.value = {'a': 2};
        return v;
      });

      expect(s.untrackedValue, {'a': 2});
      expect(w.calls, [
        [
          {'a': 1},
          {'a': 2},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    test('update whose callback changes another key notifies once', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);

      s.update('a', (v) {
        s['b'] = 3;
        return v;
      });

      expect(s.untrackedValue, {'a': 1, 'b': 3});
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          {'a': 1, 'b': 3},
        ],
      ]);
      expect(w.effectReruns, 1);
    });

    final views = <String, Map<String, int> Function(MapSignal<String, int>)>{
      'untrackedValue': (s) => s.untrackedValue,
      'a cast view': (s) => s.untrackedValue.cast<String, int>(),
    };
    for (final MapEntry(key: name, value: view) in views.entries) {
      test('update without history whose callback changes another key '
          'through $name notifies once', () {
        final s = MapSignal({'a': 1, 'b': 2}, trackPreviousValue: false);
        final w = watch(s);

        s.update('a', (v) {
          view(s)['b'] = 3;
          return v;
        });

        expect(s.untrackedValue, {'a': 1, 'b': 3});
        expect(w.calls, hasLength(1));
        expect(w.calls.single[1], {'a': 1, 'b': 3});
        expect(w.effectReruns, 1);
      });
    }

    test('update whose callback changes a new map notifies for each', () {
      final s = MapSignal({'a': 1});
      final w = watch(s);

      s.update('a', (v) {
        s
          ..value = {'a': 2}
          ..['b'] = 3;
        return v;
      });

      expect(s.untrackedValue, {'a': 2, 'b': 3});
      expect(w.calls, [
        [
          {'a': 1},
          {'a': 2},
        ],
        [
          {'a': 2},
          {'a': 2, 'b': 3},
        ],
      ]);
      expect(w.effectReruns, 2);
    });

    test('a partial change keeps its error when an effect also throws', () {
      final s = MapSignal({'a': 1});
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.length == 2) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      _expectMutationErrorWins(
        () => s.addEntries(_throwAfter([const MapEntry('b', 2)])),
      );

      expect(s.untrackedValue, {'a': 1, 'b': 2});
    });

    // A cast map throws a TypeError when it reads the value of 'unread'.
    Map<String, String> castMap() =>
        <String, Object>{'a': 'x', 'unread': 42}.cast<String, String>();

    test('remove of an absent key returns null without reading values', () {
      final s = MapSignal(castMap());
      addTearDown(s.dispose);

      expect(s.remove('absent'), isNull);
    });

    test('putIfAbsent of a present key returns it without reading values', () {
      final s = MapSignal(castMap());
      addTearDown(s.dispose);

      expect(s.putIfAbsent('a', () => 'y'), 'x');
    });

    test('update of an absent key without ifAbsent throws like the map', () {
      final s = MapSignal(castMap());
      addTearDown(s.dispose);

      expect(() => s.update('absent', (v) => v), throwsArgumentError);
    });

    test('updateValue inside an effect does not subscribe the effect', () {
      final s = MapSignal({'a': 1}, equals: true);
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        s.updateValue((map) => map);
      });
      addTearDown(effect.dispose);

      s['b'] = 2;

      expect(runs, 1);
    });

    test('[]= of the same value returns without reading other values', () {
      final s = MapSignal(castMap());
      final w = watch(s);

      s['a'] = 'x';

      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
    });

    test('clear of a cast map without history notifies once', () {
      final s = MapSignal(castMap(), trackPreviousValue: false);
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      s.clear();

      expect(s.untrackedValue, isEmpty);
      expect(runs, 2);
    });

    // Each one removes 'a' and adds it again, so 'a' moves after 'b'.
    final reorders = <String, void Function(MapSignal<String, int>)>{
      'addEntries': (s) {
        Iterable<MapEntry<String, int>> moveA() sync* {
          s.remove('a');
          yield const MapEntry('a', 1);
        }

        s.addEntries(moveA());
      },
      'update': (s) => s.update('b', (v) {
        s
          ..remove('a')
          ..['a'] = 1;
        return v;
      }),
    };
    for (final MapEntry(key: name, value: mutate) in reorders.entries) {
      test('$name with a nested reorder notifies once', () {
        final s = MapSignal({'a': 1, 'b': 2});
        addTearDown(s.dispose);
        final seen = <String>[];
        final effect = Effect(() => seen.add(s.keys.join()));
        addTearDown(effect.dispose);

        mutate(s);

        expect(seen, ['ab', 'ba']);
        expect(s.untrackedPreviousValue!.keys.join(), 'ab');
      });
    }
  });

  group('SetSignal', () {
    _Watch<Set<E>> watch<E>(SetSignal<E> s) {
      addTearDown(s.dispose);
      return _Watch<Set<E>>(s, (value) => value.toSet());
    }

    test('the previous value keeps the iteration order of the set', () {
      final s = SetSignal<int>({})
        ..value = (_NewestFirstSet()
          ..add(1)
          ..add(2));
      addTearDown(s.dispose);

      s.add(3);

      expect(s.untrackedValue.toList(), [3, 2, 1]);
      expect(s.untrackedPreviousValue!.toList(), [2, 1]);
    });

    test('a callback that assigns a value keeps the old set as previous', () {
      final s = SetSignal({1, 2});
      final w = watch(s);

      var assigned = false;
      s.removeWhere((e) {
        if (!assigned) s.value = {9};
        assigned = true;
        return e == 1;
      });

      expect(s.untrackedValue, {9});
      expect(s.previousValue, {1, 2});
      expect(w.calls.single[0], {1, 2});
    });

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

    test('a partial change keeps its error when an effect also throws', () {
      final s = SetSignal({1});
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.length == 2) throw StateError('effect');
      });
      addTearDown(effect.dispose);

      _expectMutationErrorWins(() => s.addAll(_throwAfter([2])));

      expect(s.untrackedValue, {1, 2});
    });

    // A cast set throws a TypeError when it reads 'unread'.
    Set<int> castSet() => <Object>{1, 'unread'}.cast<int>();

    test('add of a present element returns false without reading others', () {
      final s = SetSignal<int>({})..value = castSet();
      addTearDown(s.dispose);

      expect(s.add(1), isFalse);
    });

    test('remove of an absent element returns false without reading', () {
      final s = SetSignal<int>({})..value = castSet();
      addTearDown(s.dispose);

      expect(s.remove(2), isFalse);
    });

    test('updateValue inside an effect does not subscribe the effect', () {
      final s = SetSignal({1}, equals: true);
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        runs++;
        s.updateValue((set) => set);
      });
      addTearDown(effect.dispose);

      s.add(2);

      expect(runs, 1);
    });

    for (final history in [true, false]) {
      test('a nested replacement with an equal element notifies once '
          '(history: $history)', () {
        final old = DateTime.utc(2026);
        final replacement = DateTime.utc(2026);
        final s = SetSignal({old}, trackPreviousValue: history);
        addTearDown(s.dispose);
        final seen = <DateTime>[];
        final effect = Effect(() => seen.add(s.first));
        addTearDown(effect.dispose);
        Iterable<DateTime> replace() sync* {
          s.remove(old);
          yield replacement;
        }

        s.addAll(replace());

        expect(seen, [same(old), same(replacement)]);
        if (history) expect(s.untrackedPreviousValue!.single, same(old));
      });
    }

    test('a nested reorder notifies once', () {
      final s = SetSignal({1, 2});
      addTearDown(s.dispose);
      final seen = <String>[];
      final effect = Effect(() => seen.add(s.join()));
      addTearDown(effect.dispose);
      Iterable<int> moveFirst() sync* {
        s.remove(1);
        yield 1;
      }

      s.addAll(moveFirst());

      expect(seen, ['12', '21']);
      expect(s.untrackedPreviousValue!.join(), '12');
    });

    test('clear of a cast set without history notifies once', () {
      final s = SetSignal<int>({}, trackPreviousValue: false)
        ..value = castSet();
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);

      s.clear();

      expect(s.untrackedValue, isEmpty);
      expect(runs, 2);
    });
  });

  group('edge cases of typed lists and cast maps (#208)', () {
    test('a rejected add to a fixed-length typed list without history '
        'does not rerun', () {
      final list = ListSignal<Float32x4>([], trackPreviousValue: false)
        ..value = Float32x4List(1);
      addTearDown(list.dispose);
      var runs = 0;
      final effect = Effect(() {
        list.value;
        runs++;
      });
      addTearDown(effect.dispose);

      expect(() => list.add(Float32x4.zero()), throwsUnsupportedError);

      expect(runs, 1);
    });

    test('addAll of an empty map to a cast map is a no-op', () {
      final backing = <String, Object>{'unread': 42}.cast<String, String>();
      final map = MapSignal<String, String>(backing);
      addTearDown(map.dispose);
      var runs = 0;
      final effect = Effect(() {
        map.value;
        runs++;
      });
      addTearDown(effect.dispose);

      map
        ..addAll({})
        ..addEntries(<MapEntry<String, String>>[]);

      expect(runs, 1);
    });

    test('an update of an unmodifiable map without history throws first', () {
      final map = MapSignal<String, int>(
        Map.unmodifiable({'a': 1}),
        trackPreviousValue: false,
      );
      addTearDown(map.dispose);
      var calls = 0;

      expect(
        () => map.update('a', (_) {
          calls++;
          throw StateError('x');
        }),
        throwsUnsupportedError,
      );

      expect(calls, 0);
    });

    test('an update notifies when the backing write changes then throws', () {
      final backing = _WriteThenThrowMap({'a': 1});
      final map = MapSignal<String, int>(backing, trackPreviousValue: false);
      addTearDown(map.dispose);
      var runs = 0;
      final effect = Effect(() {
        map.value;
        runs++;
      });
      addTearDown(effect.dispose);

      expect(() => map.update('a', (v) => v + 1), throwsStateError);

      expect(backing['a'], 2);
      expect(runs, 2);
    });
  });
}

class _ThrowingHash {
  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => throw UnsupportedError('hashCode');
}

class _WriteThenThrowMap extends MapBase<String, int> {
  _WriteThenThrowMap(this._delegate);

  final Map<String, int> _delegate;

  @override
  int? operator [](Object? key) => _delegate[key];

  @override
  void operator []=(String key, int value) {
    _delegate[key] = value;
    throw StateError('after write');
  }

  @override
  void clear() => _delegate.clear();

  @override
  Iterable<String> get keys => _delegate.keys;

  @override
  int? remove(Object? key) => _delegate.remove(key);
}

/// A set that iterates its newest element first. `toSet` keeps the order.
class _NewestFirstSet extends SetBase<int> {
  final List<int> _elements = [];

  @override
  bool add(int value) {
    if (_elements.contains(value)) return false;
    _elements.insert(0, value);
    return true;
  }

  @override
  bool contains(Object? element) => _elements.contains(element);

  @override
  Iterator<int> get iterator => _elements.iterator;

  @override
  int get length => _elements.length;

  @override
  int? lookup(Object? element) =>
      _elements.contains(element) ? element! as int : null;

  @override
  bool remove(Object? value) => _elements.remove(value);

  @override
  Set<int> toSet() => _NewestFirstSet().._elements.addAll(_elements);
}

/// A [Random] that makes `List.shuffle` swap each element with itself.
class _NoSwapRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
