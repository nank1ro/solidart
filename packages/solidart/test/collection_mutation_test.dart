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
  _CountingList(int length)
    : _elements = List.filled(length, 0, growable: true);

  final List<int> _elements;

  @override
  void addAll(Iterable<int> iterable) => _elements.addAll(iterable);

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

class _PointList extends DelegatingList<int> {
  _PointList(super.base);
  int reads = 0;

  @override
  int operator [](int index) {
    reads++;
    return super[index];
  }

  @override
  Iterator<int> get iterator {
    reads += length;
    return super.iterator;
  }
}

class _CountingMap extends DelegatingMap<int, int> {
  _CountingMap([int entryCount = 100])
    : super({for (var i = 0; i < entryCount; i++) i: i});
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
  Iterable<int> get values {
    scans++;
    return super.values;
  }

  @override
  void forEach(void Function(int, int) action) {
    scans++;
    super.forEach(action);
  }
}

class _ReactiveMapView extends MapView<String, int> {
  _ReactiveMapView(super.map, this.dependency);

  final Signal<int> dependency;

  @override
  Iterable<String> get keys {
    dependency.value;
    return super.keys;
  }

  @override
  void forEach(void Function(String, int) action) {
    dependency.value;
    super.forEach(action);
  }
}

class _CountingSet extends DelegatingSet<int> {
  _CountingSet() : super({for (var i = 0; i < 100; i++) i});
  int scans = 0;

  @override
  Set<int> toSet() {
    scans++;
    return super.toSet();
  }

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

/// A list whose slot write runs [onWrite] once after it writes.
class _ReentrantList extends ListBase<int> {
  _ReentrantList(this._elements);

  final List<int> _elements;
  void Function()? onWrite;

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) => _elements.length = newLength;

  @override
  int operator [](int index) => _elements[index];

  @override
  void operator []=(int index, int value) {
    _elements[index] = value;
    final callback = onWrite;
    onWrite = null;
    callback?.call();
  }
}

/// A set whose add runs [onAdd] once after it adds.
class _ReentrantSet extends SetBase<int> {
  final Set<int> _elements = {};
  void Function()? onAdd;

  @override
  bool add(int value) {
    final added = _elements.add(value);
    final callback = onAdd;
    onAdd = null;
    callback?.call();
    return added;
  }

  @override
  bool contains(Object? element) => _elements.contains(element);

  @override
  Iterator<int> get iterator => _elements.iterator;

  @override
  int get length => _elements.length;

  @override
  int? lookup(Object? element) => _elements.lookup(element);

  @override
  bool remove(Object? value) => _elements.remove(value);

  @override
  Set<int> toSet() => _elements.toSet();
}

void main() {
  group('bulk mutation cost', () {
    final listWrites = <String, void Function(List<int>)>{
      'removeWhere': (list) => list.removeWhere((_) => false),
      'addAll': (list) => list.addAll([1, 2]),
    };
    for (final MapEntry(key: name, value: write) in listWrites.entries) {
      test('list $name adds no reads', () {
        final reference = _CountingList(100);
        write(reference);
        final backing = _CountingList(100);
        final s = ListSignal<int>([], trackPreviousValue: false)
          ..value = backing;
        addTearDown(s.dispose);
        write(s);
        expect(backing.reads, reference.reads);
      });
    }

    final setWrites = <String, void Function(Set<int>)>{
      'removeWhere': (set) => set.removeWhere((_) => false),
      'retainAll': (set) => set.retainAll(List.generate(100, (i) => i)),
    };
    for (final MapEntry(key: name, value: write) in setWrites.entries) {
      test('set $name adds no scans', () {
        final reference = _CountingSet();
        write(reference);
        final backing = _CountingSet();
        final s = SetSignal<int>({}, trackPreviousValue: false)
          ..value = backing;
        addTearDown(s.dispose);
        write(s);
        expect(backing.scans, reference.scans);
      });
    }

    test('map removeWhere adds no scans', () {
      final reference = _CountingMap()..removeWhere((_, _) => false);
      final backing = _CountingMap();
      final s = MapSignal<int, int>({}, trackPreviousValue: false)
        ..value = backing;
      addTearDown(s.dispose);
      s.removeWhere((_, _) => false);
      expect(backing.scans, reference.scans);
    });

    test('observed map removeWhere with equality adds no scans', () {
      bool remove(int key, int _) => key.isEven;
      final reference = _CountingMap()..removeWhere(remove);
      final backing = _CountingMap();
      final s = MapSignal(backing, equals: true, trackPreviousValue: false);
      addTearDown(s.dispose);
      var length = 0;
      final effect = Effect(() => length = s.length);
      addTearDown(effect.dispose);

      s.removeWhere(remove);

      expect(length, reference.length);
      expect(backing.scans, reference.scans);
    });

    test(
      'tracked reads after one map removal do not compare the whole map',
      () {
        var hashes = 0;
        final s = MapSignal(
          {
            for (var i = 0; i < 128; i++)
              i: _CountedMapValue(i, () => hashes++),
          },
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final effect = Effect(() {
          s.removeWhere((key, value) {
            if (key != 0) expect(s[key], same(value));
            return key == 0;
          });
        });
        addTearDown(effect.dispose);

        expect(s.untrackedValue.length, 127);
        expect(hashes, 0);
      },
    );

    for (final removes in [false, true]) {
      test(
        'tracked reads from a nested no-op '
        '${removes ? 'removeWhere' : 'updateAll'} do bounded comparisons',
        () {
          const count = 128;
          var hashes = 0;
          final s = MapSignal(
            {
              for (var i = 0; i < count; i++)
                i: _CountedMapValue(i, () => hashes++),
            },
            equals: true,
            trackPreviousValue: false,
          );
          addTearDown(s.dispose);
          final effect = Effect(() {
            s.value;
            s.update(0, (current) {
              if (removes) {
                s.removeWhere((key, value) {
                  expect(s[key], same(value));
                  return false;
                });
              } else {
                s.updateAll((key, value) => s[key]!);
              }
              return current;
            });
          });
          addTearDown(effect.dispose);

          expect(hashes, lessThanOrEqualTo(8 * count));
        },
      );
    }

    for (final (name, outer, bulk, sameValue) in [
      ('updateAll', false, true, true),
      ('a point update', true, false, true),
      ('a nested updateAll', true, true, true),
      ('updateAll', false, true, false),
      ('a point update', true, false, false),
    ]) {
      for (final opaque in [false, true]) {
        test('equal point callbacks in $name do bounded comparisons '
            '(identical: $sameValue, opaque: $opaque)', () {
          const count = 128;
          var comparisons = 0;
          _CountedMapValue valueOf(int key) => _CountedMapValue(
            key,
            () => comparisons++,
            onEquals: () => comparisons++,
          );
          final backing = {for (var i = 0; i < count; i++) i: valueOf(i)};
          final original = backing[1];
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: false,
          );
          addTearDown(s.dispose);
          _CountedMapValue read(int key) => s.update(key, (_) {
            final observed = s[key]!;
            return sameValue ? observed : valueOf(observed.key);
          });
          void updateAll() => s.updateAll((key, _) => read(key));
          final effect = Effect(() {
            s.value;
            if (!outer) return updateAll();
            s.update(0, (value) {
              if (bulk) {
                updateAll();
              } else {
                for (var key = 0; key < count; key++) {
                  read(key);
                }
              }
              return value;
            });
          });
          addTearDown(effect.dispose);

          expect(comparisons, lessThanOrEqualTo(8 * count));
          expect(identical(backing[1], original), sameValue);
        });
      }
    }

    for (final firstValueBeforeRead in [false, true]) {
      for (final opaque in [false, true]) {
        test('equal updateAll results keep reads bounded '
            '(first value before read: $firstValueBeforeRead, '
            'opaque: $opaque)', () {
          const count = 128;
          var comparisons = 0;
          _CountedMapValue valueOf(int key) => _CountedMapValue(
            key,
            () => comparisons++,
            onEquals: () => comparisons++,
          );
          final backing = {for (var i = 0; i < count; i++) i: valueOf(i)};
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: false,
          );
          addTearDown(s.dispose);
          _CountedMapValue replace(int key) =>
              s.update(key, (_) => valueOf(s[key]!.key));
          final effect = Effect(() {
            s.value;
            if (firstValueBeforeRead) {
              s.updateAll(
                (key, value) => key == 0 ? valueOf(value.key) : replace(key),
              );
            } else {
              s.update(count - 1, (value) {
                s.updateAll((key, old) {
                  replace(key);
                  return old;
                });
                return value;
              });
            }
          });
          addTearDown(effect.dispose);

          expect(comparisons, lessThanOrEqualTo(8 * count));
        });
      }
    }

    for (final (bulk, opaque, history, identicalValue) in [
      (false, false, false, false),
      (true, false, false, false),
      (false, true, false, false),
      (true, true, false, false),
      (true, true, true, true),
    ]) {
      test(
        'equal point writes reuse a first observer snapshot (bulk: $bulk, '
        'opaque: $opaque, history: $history, identical: $identicalValue)',
        () {
          const count = 128;
          var hashes = 0;
          _CountedMapValue valueOf(int key) =>
              _CountedMapValue(key, () => hashes++);
          final backing = {for (var i = 0; i < count; i++) i: valueOf(i)};
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          if (bulk) {
            final effect = Effect(() {
              s.updateAll((key, value) {
                if (key == 0) return valueOf(-1);
                return s.update(key, (_) {
                  final current = s[key]!;
                  return identicalValue ? current : valueOf(current.key);
                });
              });
            });
            addTearDown(effect.dispose);
          } else {
            s.update(0, (value) {
              s.addAll({1: valueOf(-1)});
              final effect = Effect(() => s[0]);
              addTearDown(effect.dispose);
              for (var key = 0; key < count; key++) {
                s.update(key, (current) {
                  effect.run();
                  return valueOf(current.key);
                });
              }
              return value;
            });
          }

          expect(hashes, 0);
        },
      );
    }

    for (final useSameValue in [true, false]) {
      for (final history in [false, true]) {
        test('tracked reads from equal updateAll callbacks do not hash the '
            'map (identical: $useSameValue, history: $history)', () {
          var hashes = 0;
          _CountedMapValue valueOf(int key) =>
              _CountedMapValue(key, () => hashes++);
          final s = MapSignal(
            {for (var i = 0; i < 128; i++) i: valueOf(i)},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          var runs = 0;
          final effect = Effect(() {
            runs++;
            s.updateAll((key, value) {
              final observed = s[key]!;
              return useSameValue ? observed : valueOf(observed.key);
            });
          });
          addTearDown(effect.dispose);

          expect(hashes, 0);
          final previousRuns = runs;
          s[0] = valueOf(-1);
          expect(runs, greaterThan(previousRuns));
        });
      }
    }

    for (final restore in [false, true]) {
      test('native point writes reuse a captured bulk snapshot '
          '(restored: $restore)', () {
        const count = 128;
        var hashes = 0;
        _CountedMapValue valueOf(int key) =>
            _CountedMapValue(key, () => hashes++);
        final s = MapSignal(
          {for (var i = 0; i < count; i++) i: valueOf(i)},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final effect = Effect(() {
          s.updateAll((key, _) {
            if (key == 0) return valueOf(-1);
            final current = s[key]!;
            if (restore) {
              s
                ..update(key, (_) => valueOf(-2))
                ..update(key, (_) => current);
            } else {
              s[key] = valueOf(current.key);
            }
            return current;
          });
        });
        addTearDown(effect.dispose);

        expect(hashes, 0);
      });
    }

    test('native point reads reuse a snapshot after a full match', () {
      const count = 128;
      var hashes = 0;
      _CountedMapValue valueOf(int key) =>
          _CountedMapValue(key, () => hashes++);
      final s = MapSignal(
        {for (var i = 0; i < count; i++) i: valueOf(i)},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      var hashesAfterMatch = 0;
      final effect = Effect(() {
        final original = s[1]!;
        s.update(0, (current) {
          s
            ..addAll({1: valueOf(-1)})
            ..addAll({1: original})
            ..value;
          hashesAfterMatch = hashes;
          for (var key = 0; key < count; key++) {
            final previous = s[key]!;
            s
              ..update(key, (_) => valueOf(-1))
              ..update(key, (_) => previous)
              ..value;
          }
          return current;
        });
      });
      addTearDown(effect.dispose);

      expect(hashesAfterMatch, greaterThan(0));
      expect(hashes, hashesAfterMatch);
    });

    test('a divergent native reader rechecks only journaled slots', () {
      var hashes = 0;
      _CountedMapValue valueOf(int key) =>
          _CountedMapValue(key, () => hashes++);
      final original = valueOf(0);
      final s = MapSignal(
        {for (var i = 0; i < 10000; i++) i: original},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final incumbent = Effect(() => s.value[0]);
      addTearDown(incumbent.dispose);

      s.update(0, (current) {
        s[1] = valueOf(1);
        final reader = Effect(() => s.value[1]);
        s
          ..[2] = valueOf(2)
          ..[2] = original;
        reader
          ..run()
          ..dispose();
        return current;
      });

      expect(hashes, 0);
    });

    for (final history in [false, true]) {
      test('a sparse reader releases restored slots outside its observation '
          '(history: $history)', () {
        const count = 512;
        var comparisons = 0;
        _CountedMapValue valueOf(int key) => _CountedMapValue(
          key,
          () => comparisons++,
          onEquals: () => comparisons++,
        );
        final initial = {for (var i = 0; i <= count; i++) i: valueOf(0)};
        final s = MapSignal(
          Map.of(initial),
          equals: true,
          trackPreviousValue: history,
        );
        addTearDown(s.dispose);
        final incumbentValues = <int>[];
        final incumbent = Effect(() => incumbentValues.add(s.value[0]!.key));
        addTearDown(incumbent.dispose);
        final laterValues = <int>[];
        late int comparisonsDuringReads;

        batch(() {
          s.update(0, (current) {
            s[0] = valueOf(1);
            final reader = Effect(() => s.value[0]);
            comparisons = 0;
            for (var key = 1; key <= count; key++) {
              s
                ..update(key, (_) => valueOf(2))
                ..update(key, (_) => valueOf(0));
              reader.run();
            }
            comparisonsDuringReads = comparisons;
            reader.dispose();
            s[0] = current;
            final later = Effect(() => laterValues.add(s.value[0]!.key));
            addTearDown(later.dispose);
            s
              ..[0] = valueOf(2)
              ..value = initial;
            return current;
          });
        });

        expect(comparisonsDuringReads, lessThanOrEqualTo(8 * count));
        expect(incumbentValues, [0]);
        expect(laterValues, [0]);
      });

      for (final opaque in [false, true]) {
        test('equal slot assignments keep tracked rereads bounded '
            '(history: $history, opaque: $opaque)', () {
          const count = 128;
          var hashes = 0;
          _CountedMapValue valueOf(int key) =>
              _CountedMapValue(key, () => hashes++);
          final backing = {for (var i = 0; i < count; i++) i: valueOf(i)};
          final original = backing[1];
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          var runs = 0;
          final incumbent = Effect(() {
            s.value;
            runs++;
          });
          addTearDown(incumbent.dispose);

          s.update(0, (current) {
            for (var key = 1; key < count; key++) {
              s[key] = valueOf(key);
              incumbent.run();
            }
            return current;
          });

          expect(hashes, 0);
          expect(runs, count + 1);
          expect(s.untrackedValue[1], isNot(same(original)));
          expect(s.untrackedPreviousValue?[1], same(history ? original : null));
        });
      }
    }

    test('tracked reads release slots restored by nested point callbacks', () {
      const count = 256;
      var comparisons = 0;
      _CountedMapValue valueOf(int key) => _CountedMapValue(
        key,
        () => comparisons++,
        onEquals: () => comparisons++,
      );
      final s = MapSignal(
        {for (var i = 0; i < count; i++) i: valueOf(0)},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final effect = Effect(() {
        s.value;
        s.update(0, (current) {
          for (var key = 0; key < count; key++) {
            s
              ..update(key, (_) => valueOf(1))
              ..update(key, (_) => valueOf(0))
              ..value;
          }
          return current;
        });
      });
      addTearDown(effect.dispose);

      expect(comparisons, lessThanOrEqualTo(8 * count));
    });

    test('list fillRange reads only the affected slots', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      s.fillRange(50, 53, 0);
      expect(backing.reads, lessThanOrEqualTo(6));
    });
  });

  group('lazy collection history', () {
    test('a typed-list fill that the list converts keeps exact history', () {
      final s = ListSignal<int>([])..value = Uint8List.fromList([0, 1, 2]);
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);

      s[2] = 3;
      // A Uint8List stores 256 as 0, so slot 0 keeps its value.
      s.fillRange(0, 2, 256);

      expect(calls, 2);
      expect(s.untrackedValue, [0, 0, 3]);
      expect(s.untrackedPreviousValue, [0, 1, 3]);
    });

    test('a set add on a widened or custom set copies before the write', () {
      final widened = <int>{1, 2};
      final custom = LinkedHashSet<String>(
        equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
        hashCode: (a) => a.toLowerCase().hashCode,
      )..add('a');
      final w = SetSignal<num>({})..value = widened;
      final c = SetSignal<String>({})..value = custom;
      addTearDown(w.dispose);
      addTearDown(c.dispose);

      w.add(3);
      c.add('b');
      // A raw write after the signal write shows only in lazy history.
      widened.add(7);
      custom.add('z');

      expect(w.untrackedPreviousValue, {1, 2});
      expect(c.untrackedPreviousValue!.toList(), ['a']);
      expect(c.untrackedPreviousValue!.contains('A'), isTrue);
    });

    test('a set add on a default set stays lazy', () {
      final backing = <int>{1, 2};
      final s = SetSignal<int>({})..value = backing;
      addTearDown(s.dispose);

      s.add(3);
      // A pending undo step is applied to the current set at read time.
      backing.add(7);

      expect(s.untrackedPreviousValue, {1, 2, 7});
    });

    test('a duplicate set add without history changes nothing', () {
      final backing = _CountingSet();
      final s = SetSignal<int>({}, trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);
      backing.scans = 0;

      expect(s.add(5), isFalse);

      expect(backing.scans, 0);
      expect(calls, 0);
    });

    for (final (name, write) in <(String, void Function(ListSignal<int>))>[
      ('removeAt(0)', (s) => s.removeAt(0)),
      ('removeAt(2)', (s) => s.removeAt(2)),
      ('removeAt(4)', (s) => s.removeAt(4)),
      ('removeLast', (s) => s.removeLast()),
      ('insert(0)', (s) => s.insert(0, 9)),
      ('insert(2)', (s) => s.insert(2, 9)),
      ('insert(5)', (s) => s.insert(5, 9)),
    ]) {
      test('a default list $name builds the previous list', () {
        final s = ListSignal([1, 2, 3, 4, 5]);
        addTearDown(s.dispose);

        write(s);
        final previous = s.untrackedPreviousValue!;

        expect(previous, [1, 2, 3, 4, 5]);
        expect(previous, isNot(same(s.untrackedValue)));
        previous.add(6);
        expect(previous.length, 6);
      });
    }

    test('a lazy list write that writes through the signal keeps no '
        'previous value', () {
      final backing = _ReentrantList([1, 2]);
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);
      backing.onWrite = () => s[1] = 8;

      s[0] = 9;

      expect(s.untrackedValue, [9, 8]);
      expect(calls, 1);
      expect(s.untrackedHasPreviousValue, isFalse);
      expect(s.untrackedPreviousValue, isNull);
    });

    test('a custom set add that adds through the signal keeps its copy', () {
      // A custom set is not a default set, so it copies before the write,
      // and that copy stays right when the backing writes through the signal.
      final backing = _ReentrantSet();
      final s = SetSignal<int>({})..value = backing;
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);
      backing.onAdd = () => s.add(2);

      s.add(1);

      expect(s.untrackedValue, {1, 2});
      expect(calls, 1);
      expect(s.untrackedHasPreviousValue, isTrue);
      expect(s.untrackedPreviousValue, isEmpty);
    });

    final writes = <String, void Function(ListSignal<int>)>{
      'slot': (s) => s[40] = -1,
      'first': (s) => s.first = -1,
      'last': (s) => s.last = -1,
      'add': (s) => s.add(-1),
      'insert': (s) => s.insert(40, -1),
      'removeAt': (s) => s.removeAt(40),
      'removeLast': (s) => s.removeLast(),
    };
    for (final entry in writes.entries) {
      test('list ${entry.key} copies only at the first read', () {
        final before = List.generate(100, (i) => i);
        final backing = _PointList(before.toList());
        final s = ListSignal<int>([])..value = backing;
        addTearDown(s.dispose);
        entry.value(s);
        expect(backing.reads, lessThanOrEqualTo(2));
        final previous = s.previousValue;
        expect(previous, orderedEquals(before));
        final reads = backing.reads;
        expect(reads, greaterThanOrEqualTo(backing.length));
        expect(s.untrackedPreviousValue, same(previous));
        expect(backing.reads, reads);
      });
    }

    for (final key in ['b', 'c']) {
      test('default map builds history on the first read for $key', () {
        final backing = <String, int?>{'a': 1, 'b': null};
        final s = MapSignal(backing);
        addTearDown(s.dispose);
        s[key] = 5;
        // An external write is visible only if the copy is still pending.
        backing['a'] = 2;
        final previous = s.previousValue!;
        expect(previous, {'a': 2, 'b': null});
        expect(previous.keys, orderedEquals(['a', 'b']));
        backing['a'] = 3;
        expect(s.untrackedPreviousValue, same(previous));
        expect(previous['a'], 2);
      });
    }

    test('a failing history read can retry without tracking key reads', () {
      final dependency = Signal(0);
      addTearDown(dependency.dispose);
      var fail = false;
      var hashes = 0;
      final key = _HashKey(() {
        hashes++;
        dependency.value;
        if (fail) throw StateError('hash');
        return 1;
      });
      final s = MapSignal<Object, int>({key: 0});
      addTearDown(s.dispose);
      hashes = 0;
      // A new value key is lazy, so the write copies nothing.
      s['b'] = 1;
      expect(hashes, 0);
      fail = true;
      // A void closure: the matcher must not hash a returned map itself.
      expect(() {
        s.previousValue;
      }, throwsStateError);
      fail = false;
      var runs = 0;
      final effect = Effect(() {
        runs++;
        final previous = s.untrackedPreviousValue!;
        expect(previous.length, 1);
        expect(identical(previous.keys.single, key), isTrue);
        expect(previous.values.single, 0);
      });
      addTearDown(effect.dispose);
      dependency.value++;
      expect(runs, 1);
    });

    test('custom and identity maps copy history before the write', () {
      final maps = [
        LinkedHashMap<String, int>(
          equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
          hashCode: (a) => a.toLowerCase().hashCode,
        ),
        Map<String, int>.identity(),
      ];
      for (final backing in maps) {
        backing['A'] = 1;
        final s = MapSignal(backing);
        addTearDown(s.dispose);
        s['a'] = 2;
        backing['extra'] = 3;
        expect(s.previousValue, {'A': 1});
      }
    });

    test('an addListener listener does not build history', () {
      final backing = _PointList(List.generate(100, (i) => i));
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      var calls = 0;
      void listener() => calls++;
      s.addListener(listener);
      addTearDown(() => s.removeListener(listener));
      final reads = backing.reads;
      s[0] = -1;
      expect(calls, 1);
      // Only the slot write reads the list: no history copy.
      expect(backing.reads, lessThanOrEqualTo(reads + 2));
      final seen = <List<int>?>[];
      final dispose = s.observe((prev, _) => seen.add(prev));
      addTearDown(dispose);
      s[1] = -2;
      expect(calls, 2);
      expect(
        seen.single,
        orderedEquals([-1, ...List.generate(99, (i) => i + 1)]),
      );
    });

    for (final (name, write) in <(String, void Function(ListSignal<int>))>[
      ('removeAt(0)', (s) => s.removeAt(0)),
      ('removeAt(middle)', (s) => s.removeAt(50)),
      ('removeAt(last)', (s) => s.removeAt(99)),
      ('removeLast', (s) => s.removeLast()),
    ]) {
      test('$name rebuilds the previous list in order', () {
        final before = List.generate(100, (i) => i);
        final s = ListSignal(List.of(before));
        addTearDown(s.dispose);
        write(s);
        final previous = s.previousValue!;
        expect(previous, orderedEquals(before));
        // The previous value is a growable list.
        previous.add(100);
        expect(previous.length, 101);
      });
    }

    test('an overwrite through an equal mutable key keeps the old map', () {
      final stored = _MutableKey(1);
      final s = MapSignal<_MutableKey, int>({stored: 1});
      addTearDown(s.dispose);
      final lookup = _MutableKey(1);
      s[lookup] = 2;
      // The caller may change its lookup key after the write.
      lookup.id = 2;
      final previous = s.previousValue!;
      expect(previous.length, 1);
      expect(previous.keys.single, same(stored));
      expect(previous[stored], 1);
    });

    test('an int key overwrite keeps the lazy history', () {
      final backing = <int, int>{1: 1, 2: 2};
      final s = MapSignal(backing);
      addTearDown(s.dispose);
      s[1] = 5;
      // An external write is visible only if the copy is still pending.
      backing[2] = 3;
      expect(s.previousValue, {1: 1, 2: 3});
    });

    test('a NaN key or element is not undone lazily', () {
      final map = MapSignal<double, int>({});
      addTearDown(map.dispose);
      map[double.nan] = 1;
      expect(map.previousValue, isEmpty);
      final set = SetSignal<double>({});
      addTearDown(set.dispose);
      set.add(double.nan);
      expect(set.previousValue, isEmpty);
    });

    test('list add answers hasPreviousValue without a copy', () {
      final backing = _PointList(List.generate(100, (i) => i));
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      s.add(-1);
      final reads = backing.reads;
      expect(s.untrackedHasPreviousValue, isTrue);
      expect(s.hasPreviousValue, isTrue);
      expect(backing.reads, reads);
      expect(s.previousValue, orderedEquals(List.generate(100, (i) => i)));
      expect(backing.reads, greaterThan(reads));
    });

    test('default map answers hasPreviousValue without a copy', () {
      final backing = <String, int>{'a': 1};
      final s = MapSignal(backing);
      addTearDown(s.dispose);
      s['b'] = 5;
      expect(s.untrackedHasPreviousValue, isTrue);
      // The copy is still pending, so a later external write shows in it.
      backing['a'] = 2;
      expect(s.previousValue, {'a': 2});
    });

    test('a custom set add copies before the write', () {
      // Only a default set is lazy: a custom set copies before the write.
      final backing = _CountingSet();
      final s = SetSignal<int>({})..value = backing;
      addTearDown(s.dispose);
      s
        ..add(-1)
        ..add(-1);
      expect(backing.scans, 1);
      expect(s.hasPreviousValue, isTrue);
      expect(s.untrackedHasPreviousValue, isTrue);
      expect(backing.scans, 1);
      final previous = s.previousValue;
      expect(backing.scans, 1);
      expect(previous, orderedEquals(List.generate(100, (i) => i)));
      expect(s.untrackedPreviousValue, same(previous));
      expect(backing.scans, 1);
    });

    test('later writes replace history and no-ops keep it', () {
      final s = ListSignal([1])
        ..add(2)
        ..add(3)
        ..last = 3;
      addTearDown(s.dispose);
      expect(s.toString(), contains('previousValue: [1, 2]'));
      s
        ..add(4)
        ..removeWhere((v) => v.isEven);
      expect(s.untrackedPreviousValue, [1, 2, 3, 4]);
      s
        ..add(5)
        ..value = [8];
      expect(s.previousValue, [1, 3, 5]);
    });

    test('history reads track the signal once', () {
      final s = ListSignal([1]);
      addTearDown(s.dispose);
      final seen = <List<int>?>[];
      final effect = Effect(() => seen.add(s.previousValue));
      addTearDown(effect.dispose);
      s.add(2);
      expect(s.untrackedPreviousValue, same(seen.last));
      expect(seen, [
        null,
        [1],
      ]);
    });

    test('a rejected add preserves pending history', () {
      final s = ListSignal<int>([])
        ..value = List.filled(2, 1)
        ..first = 2;
      addTearDown(s.dispose);
      final w = _Watch<List<int>>(s, List.of);
      expect(() => s.add(3), throwsUnsupportedError);
      expect(s.previousValue, [1, 1]);
      expect(w.effectReruns, 0);
    });

    test('a callback reads the history from before the outer write', () {
      final s = ListSignal([1, 2])..add(3);
      addTearDown(s.dispose);
      s.removeWhere((v) {
        if (v == 2) {
          s[0] = 7;
          expect(s.previousValue, [1, 2]);
        }
        return false;
      });
      expect(s.previousValue, [1, 2, 3]);
    });

    for (final caught in [false, true]) {
      test('a nested failed eager resize notifies once (caught: $caught)', () {
        final s = ListSignal<int>([])..value = _FixedLengthList([1, 2, 3, 4]);
        addTearDown(s.dispose);
        final w = _Watch<List<int>>(s, List.of);
        if (caught) {
          s.removeWhere((v) {
            if (v == 1) expect(() => s.remove(1), throwsUnsupportedError);
            return false;
          });
        } else {
          Iterable<int> input() sync* {
            s.remove(3);
            yield 9;
          }

          expect(() => s.setRange(0, 1, input()), throwsUnsupportedError);
        }
        final after = caught ? [2, 3, 4, 4] : [1, 2, 4, 4];
        expect(s.value, after);
        expect(w.calls, [
          [
            [1, 2, 3, 4],
            after,
          ],
        ]);
        expect(w.effectReruns, 1);
      });
    }

    test('a sort with a caught nested failed resize does not notify', () {
      final s = ListSignal(List.generate(63, (i) => i))..add(63);
      addTearDown(s.dispose);
      final w = _Watch<List<int>>(s, List.of);
      s.sort((a, b) {
        expect(() => s.removeRange(-1, 0), throwsRangeError);
        return a.compareTo(b);
      });
      expect(s.value, List.generate(64, (i) => i));
      expect(w.calls, isEmpty);
      expect(w.effectReruns, 0);
      expect(s.previousValue, List.generate(63, (i) => i));
    });

    test('removeLast on a cast list with an unreadable last element', () {
      final s = ListSignal<int>([])..value = <Object>[1, 'x'].cast<int>();
      addTearDown(s.dispose);
      final w = _Watch<List<int>>(s, List.of);
      expect(s.removeLast, throwsA(isA<TypeError>()));
      expect(s.value, [1]);
      expect(w.effectReruns, 1);
      expect(s.hasPreviousValue, isFalse);
    });

    test('removeLast saves its history without an indexed read', () {
      final backing = _SequentialList([1, 2, 3]);
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      backing.reads = 0;
      expect(s.removeLast(), 3);
      expect(backing.reads, 0);
      expect(s.previousValue, [1, 2, 3]);
    });

    for (final (name, write, expected)
        in <(String, void Function(ListSignal<int>), List<int>)>[
          ('removeAt(0)', (s) => s.removeAt(0), [1, 2, 3, 4]),
          ('removeAt(2)', (s) => s.removeAt(2), [1, 2, 3, 4]),
          ('removeAt(3)', (s) => s.removeAt(3), [1, 2, 3, 4]),
          ('removeLast', (s) => s.removeLast(), [1, 2, 3, 4]),
          ('insert(0)', (s) => s.insert(0, 9), [1, 2, 3, 4]),
          ('insert(2)', (s) => s.insert(2, 9), [1, 2, 3, 4]),
          ('insert(4)', (s) => s.insert(4, 9), [1, 2, 3, 4]),
        ]) {
      test('the first history read after $name reads the list once', () {
        final backing = _SequentialList([1, 2, 3, 4]);
        final s = ListSignal<int>([])..value = backing;
        addTearDown(s.dispose);
        write(s);
        backing.reads = 0;
        final previous = s.previousValue!;
        expect(previous, expected);
        expect(backing.reads, 0);
        previous.add(5);
        expect(previous, [...expected, 5]);
      });
    }

    test('a lazy insert builds history without the new entry', () {
      final map = MapSignal({'a': 1, 'b': 2})..['c'] = 3;
      addTearDown(map.dispose);
      expect(map.previousValue, {'a': 1, 'b': 2});
      expect(map.previousValue!.keys, ['a', 'b']);
      final set = SetSignal({1, 2})..add(3);
      addTearDown(set.dispose);
      expect(set.previousValue, {1, 2});
      expect(set.previousValue!.toList(), [1, 2]);
      final custom = SetSignal<String>({})
        ..value = LinkedHashSet<String>(
          equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
          hashCode: (a) => a.toLowerCase().hashCode,
        )
        ..add('A')
        ..add('b');
      addTearDown(custom.dispose);
      final previous = custom.previousValue!;
      expect(previous, {'A'});
      expect(previous.contains('a'), isTrue);
    });

    test('a rejected typed list slot write keeps its history', () {
      final s = ListSignal<Float32x4>([])
        ..value = Float32x4List(1).asUnmodifiableView();
      addTearDown(s.dispose);
      final w = _Watch<List<Float32x4>>(s, List.of);
      expect(() => s.first = Float32x4.zero(), throwsUnsupportedError);
      expect(w.effectReruns, 0);
      expect(s.previousValue, isEmpty);
    });

    test('removeWhere owns history for its nested point write', () {
      final s = ListSignal([1, 2])..add(3);
      addTearDown(s.dispose);
      s.removeWhere((v) {
        if (v == 2) s[0] = 7;
        return false;
      });
      expect(s.value, [7, 2, 3]);
      expect(s.previousValue, [1, 2, 3]);
    });
  });

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

    final keyWrites = <String, void Function(MapSignal<int, int>)>{
      'update that keeps the value': (s) => s.update(50, (v) => v),
      'update that changes the value': (s) => s.update(50, (v) => -1),
      'putIfAbsent of a missing key': (s) => s.putIfAbsent(100, () => -1),
      'addAll that keeps the value': (s) => s.addAll({50: 50}),
      'addAll that changes a value': (s) => s.addAll({50: -1}),
    };
    for (final MapEntry(key: name, value: write) in keyWrites.entries) {
      test('map $name without history does not scan the map', () {
        final backing = _CountingMap();
        final s = MapSignal<int, int>({}, trackPreviousValue: false)
          ..value = backing;
        addTearDown(s.dispose);
        backing.scans = 0;
        write(s);
        expect(backing.scans, 0);
      });
    }

    final listNoOps = <String, void Function(ListSignal<int>)>{
      'length = length': (s) => s.length = 100,
      'addAll of an empty list': (s) => s.addAll(const []),
      'insertAll of an empty list': (s) => s.insertAll(0, const []),
    };
    for (final MapEntry(key: name, value: write) in listNoOps.entries) {
      test('list $name with history does not copy the list', () {
        final backing = _CountingList(100);
        final s = ListSignal<int>([])..value = backing;
        addTearDown(s.dispose);
        backing.reads = 0;
        write(s);
        expect(backing.reads, 0);
      });
    }

    final setNoOps = <String, void Function(SetSignal<int>)>{
      'addAll of an empty set': (s) => s.addAll(const {}),
      'removeAll of an empty list': (s) => s.removeAll(const []),
    };
    for (final MapEntry(key: name, value: write) in setNoOps.entries) {
      test('set $name with history does not copy the set', () {
        final backing = _CountingSet();
        final s = SetSignal<int>({})..value = backing;
        addTearDown(s.dispose);
        backing.scans = 0;
        write(s);
        expect(backing.scans, 0);
      });
    }

    test('list fillRange with history reads the range only for the check', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      backing.reads = 0;
      s.fillRange(0, 3, 1);
      // One slot for the stored value, the first slot of the range, one copy
      // for the previous value, then that slot again.
      expect(backing.reads, lessThanOrEqualTo(103));
    });
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

    for (final changed in [true, false]) {
      test('removeWhere with a nested slot write (changed: $changed)', () {
        final s = ListSignal([1, 2]);
        final w = watch(s);
        s.removeWhere((_) {
          s[1] = changed ? 99 : 2;
          return false;
        });
        expect(w.effectReruns, changed ? 1 : 0);
        expect(w.calls, hasLength(changed ? 1 : 0));
        if (changed) expect(s.untrackedPreviousValue, [1, 2]);
      });
    }

    test('nested writes that restore the original slot notify once', () {
      final s = ListSignal([1, 2], trackPreviousValue: false);
      final w = watch(s);
      s.removeWhere((value) {
        if (value == 1) {
          s.retainWhere((_) {
            s
              ..[1] = 99
              ..[1] = 2;
            return true;
          });
        }
        return false;
      });
      expect(w.effectReruns, 1);
      expect(w.calls, hasLength(1));
      expect(s.untrackedValue, [1, 2]);
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

    test('setAll consumes a lazy input once and reports a partial write', () {
      final s = ListSignal([1, 2, 3], trackPreviousValue: false);
      final w = watch(s);
      var iterations = 0;
      Iterable<int> source() sync* {
        iterations++;
        yield 9;
        throw StateError('interrupted');
      }

      expect(() => s.setAll(1, source()), throwsStateError);
      expect(s.untrackedValue, [1, 9, 3]);
      expect(w.effectReruns, 1);
      expect(iterations, 1);
    });

    for (final history in [false, true]) {
      test('setAll sees a raw write that its lazy input makes ahead '
          '(history $history)', () {
        final s = ListSignal<int>([1, 2, 3], trackPreviousValue: history);
        final w = watch(s);
        final raw = s.untrackedValue;
        Iterable<int> input() sync* {
          yield 1;
          raw[1] = 99;
          yield 99;
        }

        s.setAll(0, input());

        expect(s.untrackedValue, [1, 99, 3]);
        expect(w.effectReruns, 1);
      });
    }

    test('setAll on a typed list preserves lazy input evaluation', () {
      final s = ListSignal<int>([], trackPreviousValue: false)
        ..value = Uint8List(2);
      addTearDown(s.dispose);
      var reads = 0;
      final input = [1, 2].map((i) {
        reads++;
        return i;
      });
      s.setAll(0, input);
      expect(reads, 2);
      expect(s.untrackedValue, [1, 2]);
    });

    test('fillRange can overwrite an unreadable slot without history', () {
      final s = ListSignal<int>([], trackPreviousValue: false)
        ..value = <Object>['bad'].cast<int>();
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      s.fillRange(0, 1, 1);
      expect(s.single, 1);
      expect(runs, 2);
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
          null,
          [2, 3, 3],
        ],
      ]);
      expect(w.effectReruns, 1);
      expect(s.hasPreviousValue, isFalse);
      expect(s.untrackedPreviousValue, isNull);
    });

    final shiftThenThrow = <String, void Function(ListSignal<int>)>{
      'removeWhere': (s) => s.removeWhere((x) => x == 1),
      'remove': (s) => s.remove(1),
      'removeRange': (s) => s.removeRange(0, 1),
    };
    for (final MapEntry(key: name, value: mutate) in shiftThenThrow.entries) {
      test('a $name that moves elements and then throws notifies once', () {
        final s = ListSignal<int>([])..value = _FixedLengthList([1, 2, 3]);
        final w = watch(s);

        expect(() => mutate(s), throwsUnsupportedError);

        expect(s.untrackedValue, [2, 3, 3]);
        expect(w.calls, [
          [
            [1, 2, 3],
            [2, 3, 3],
          ],
        ]);
        expect(w.effectReruns, 1);
      });
    }

    test(
      'a replaceRange that moves elements and then throws notifies once',
      () {
        final s = ListSignal<int>([])..value = _FixedLengthList([1, 1, 3]);
        final w = watch(s);

        expect(() => s.replaceRange(0, 1, const []), throwsUnsupportedError);

        expect(s.untrackedValue, [1, 3, 3]);
        expect(w.calls, [
          [
            [1, 1, 3],
            [1, 3, 3],
          ],
        ]);
        expect(w.effectReruns, 1);
      },
    );
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

    for (final history in [false, true]) {
      test('a replacement matching the retired map still delivers a nested '
          'write at batch flush, history $history', () {
        final s = MapSignal(
          {'a': 1, 'b': 1},
          equals: true,
          trackPreviousValue: history,
        );
        final w = watch(s);

        batch(() {
          s.update('a', (_) {
            s['b'] = 2;
            s.value = {'a': 2, 'b': 2};
            return 2;
          });
          expect(w.effectReruns, 0);
          expect(w.calls, isEmpty);
        });

        expect(w.effectReruns, 1);
        final previous = history ? {'a': 1, 'b': 1} : null;
        expect(w.calls, [
          [
            previous,
            {'a': 2, 'b': 2},
          ],
        ]);
      });

      test('batched update with an equal replacement notifies once, '
          'history $history', () {
        final backing = {'a': 1};
        final s = MapSignal(backing, equals: true, trackPreviousValue: history);
        addTearDown(s.dispose);
        final changed = <int?>[];
        final effect = Effect(() => changed.add(s.value['a']));
        addTearDown(effect.dispose);
        final replacement = {'a': 2};

        batch(() {
          s.update('a', (_) {
            s.value = replacement;
            return 2;
          });
          expect(changed, [1]);
        });

        expect(backing, {'a': 2});
        expect(s.untrackedValue, same(replacement));
        expect(changed, [1, 2]);
        expect(s.untrackedPreviousValue, history ? {'a': 1} : null);

        backing['a'] = 3;
        expect(s.value, same(replacement));
        expect(changed, [1, 2]);
      });

      test('batched update can restore equal contents, history $history', () {
        final backing = {'a': 1};
        final s = MapSignal(backing, equals: true, trackPreviousValue: history);
        final w = watch(s);

        batch(() {
          s.update('a', (value) {
            s.value = {'a': 1};
            return value;
          });
        });
        expect(s.untrackedValue, same(backing));
        expect(s.untrackedHasPreviousValue, isFalse);

        batch(() {
          s.update('a', (_) {
            s
              ..value = {'a': 2}
              ..value = {'a': 1};
            return 2;
          });
        });

        expect(backing, {'a': 2});
        expect(s.untrackedValue, {'a': 1});
        expect(w.effectReruns, 0);
        expect(w.calls, isEmpty);
      });

      test('batched update can restore equal contents after nested writes, '
          'history $history', () {
        final s = MapSignal(
          {'a': 1, 'b': 1},
          equals: true,
          trackPreviousValue: history,
        );
        final w = watch(s);

        batch(() {
          s.update('a', (value) {
            s
              ..['b'] = 2
              ..['b'] = 1
              ..value = {'a': 2, 'b': 1}
              ..value = {'a': 1, 'b': 1};
            return value;
          });
        });

        expect(s.untrackedValue, {'a': 1, 'b': 1});
        expect(w.effectReruns, 0);
        expect(w.calls, isEmpty);
      });
    }

    test(
      'a nested replacement rewinds the first value of each written slot',
      () {
        final initial = <String, int?>{'a': 1, 'b': null, 'f': 9};
        final s = MapSignal(
          Map.of(initial),
          equals: true,
          trackPreviousValue: false,
        );
        final w = watch(s);

        batch(() {
          s.update('a', (value) {
            s
              ..remove('b')
              ..putIfAbsent('b', () => 2)
              ..putIfAbsent('c', () => 3)
              ..update('c', (_) => 4)
              ..update('d', (_) => 5, ifAbsent: () => 5)
              ..['e'] = null
              ..remove('f')
              ..value = initial;
            return value;
          });
        });

        expect(s.untrackedValue, initial);
        expect(w.effectReruns, 0);
        expect(w.calls, isEmpty);
      },
    );

    test('a nested replacement rewinds equal keys in a default map', () {
      final initial = <num, int>{0: 1, 1.0: 7};
      final s = MapSignal(
        Map.of(initial),
        equals: true,
        trackPreviousValue: false,
      );
      final w = watch(s);

      batch(() {
        s.update(0, (value) {
          s
            ..remove(1.0)
            ..[1] = 2
            ..value = initial;
          return value;
        });
      });

      expect(w.effectReruns, 0);
      expect(w.calls, isEmpty);
    });

    for (final opaque in [false, true]) {
      for (final history in [false, true]) {
        test('shouldUpdate sees a nested write before a replacement without '
            'subscribers (opaque: $opaque, history: $history)', () {
          final initial = {'a': 1, 'b': 1};
          final s = MapSignal(
            opaque ? MapView(initial) : initial,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);

          batch(() {
            s.update('a', (_) {
              s
                ..['b'] = 2
                ..value = {'a': 3, 'b': 2}
                ..value = {'a': 1, 'b': 2};
              return 2;
            });
          });

          expect(s.listenerCount, 0);
          expect(s.shouldUpdate(), isTrue);
          expect(s.value, {'a': 1, 'b': 2});
        });
      }
    }

    test('an unobserved bulk write after a nested slot write keeps the raw '
        'replacement comparison', () {
      final s = MapSignal(
        {'a': 1, 'b': 1, 'c': 1},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);

      batch(() {
        s.update('a', (_) {
          s
            ..['b'] = 2
            ..updateAll((key, value) => key == 'c' ? 3 : value)
            ..value = {'a': 1, 'b': 1, 'c': 3};
          return 2;
        });
      });

      expect(s.shouldUpdate(), isTrue);
      expect(s.value, {'a': 1, 'b': 1, 'c': 3});
    });

    test('a nested replacement preserves distinct equal identity keys', () {
      final first = _Same(1);
      final second = _Same(2);
      final initial = Map<_Same, int>.identity()
        ..[first] = 1
        ..[second] = 2;
      final s = MapSignal(
        Map<_Same, int>.identity()..addAll(initial),
        equals: true,
        trackPreviousValue: false,
      );
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      addTearDown(s.dispose);

      batch(() {
        s.update(first, (value) {
          s
            ..[second] = 3
            ..value = initial;
          return value;
        });
      });

      expect(s.untrackedValue.length, 2);
      expect(runs, 1);
    });

    for (final (opaque, restoresInitial) in [
      (false, false),
      (false, true),
      (true, true),
    ]) {
      test('a subscriber added during a nested write sees the replacement, '
          'opaque: $opaque, restores initial: $restoresInitial', () {
        final initial = {'a': 1, 'b': 1};
        final s = MapSignal(
          opaque ? MapView(initial) : initial,
          equals: true,
          trackPreviousValue: false,
        );
        watch(s);
        final seen = <Map<String, int>>[];
        final next = restoresInitial ? {'a': 1, 'b': 1} : {'a': 2, 'b': 2};

        batch(() {
          s.update('a', (_) {
            s['b'] = 2;
            final effect = Effect(() => seen.add(Map.of(s.value)));
            addTearDown(effect.dispose);
            s.value = next;
            return next['a']!;
          });
          expect(seen, [
            {'a': 1, 'b': 2},
          ]);
        });

        expect(seen, [
          {'a': 1, 'b': 2},
          next,
        ]);
      });
    }

    for (final opaque in [false, true]) {
      for (final history in [false, true]) {
        test('a first subscriber after an unobserved nested write sees the '
            'replacement (opaque: $opaque, history: $history)', () {
          final initial = {'a': 1, 'b': 1};
          final s = MapSignal(
            opaque ? MapView(initial) : initial,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final seen = <int?>[];

          batch(() {
            s.update('a', (_) {
              if (opaque) {
                s['b'] = 2;
              } else {
                s.addAll({'b': 2});
              }
              final effect = Effect(() => seen.add(s.value['b']));
              addTearDown(effect.dispose);
              s
                ..['b'] = 3
                ..value = {'a': 2, 'b': 3};
              return 2;
            });
            expect(seen, [2]);
          });

          expect(seen, [2, 3]);
          expect(s.previousValue, history ? {'a': 1, 'b': 1} : null);
        });
      }
    }

    for (final opaque in [false, true]) {
      for (final history in [false, true]) {
        test('a first subscriber during a nested bulk write sees the final '
            'map (opaque: $opaque, history: $history)', () {
          final initial = {'a': 1, 'b': 1, 'c': 1};
          final s = MapSignal(
            opaque ? MapView(initial) : initial,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final seen = <int?>[];
          final next = opaque ? {'a': 1, 'c': 1} : {'a': 2, 'b': 2, 'c': 2};

          void subscribe() {
            final effect = Effect(() => seen.add(s.value['b']));
            addTearDown(effect.dispose);
          }

          batch(() {
            s.update('a', (_) {
              if (opaque) {
                s.removeWhere((key, value) {
                  if (key != 'b') return false;
                  subscribe();
                  return true;
                });
              } else {
                s.updateAll((key, value) {
                  if (key == 'b') subscribe();
                  return 2;
                });
              }
              s
                ..value = {...next, 'a': 3}
                ..value = next;
              return next['a']!;
            });
            expect(seen, [1]);
          });

          expect(seen, [1, next['b']]);
        });
      }
    }

    for (final history in [false, true]) {
      for (final keepReader in [false, true]) {
        test('a restored replacement updates a live intermediate reader '
            '(history: $history, live: $keepReader)', () {
          final s = MapSignal(
            {'x': 0},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final incumbentValues = <int>[];
          final incumbent = Effect(() => incumbentValues.add(s['x']!));
          addTearDown(incumbent.dispose);
          final readerValues = <int>[];

          batch(() {
            s.update('x', (current) {
              s['x'] = 1;
              final transient = Effect(() => s['x']);
              if (keepReader) {
                final reader = Effect(() => readerValues.add(s['x']!));
                addTearDown(reader.dispose);
              }
              transient.dispose();
              s.value = {'x': 0};
              return current;
            });
          });

          expect(incumbentValues, [0, if (keepReader) 0]);
          expect(readerValues, [
            if (keepReader) ...[1, 0],
          ]);
        });
      }
    }

    for (final history in [false, true]) {
      for (final opaque in [false, true]) {
        test('a computed establishes a new observation after reattaching '
            '(history: $history, opaque: $opaque)', () {
          final backing = {'x': 0};
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: history,
            autoDispose: false,
          );
          addTearDown(s.dispose);
          final gate = Signal(true, autoDispose: false);
          addTearDown(gate.dispose);
          final computed = Computed(
            () => gate.value ? s.value['x']! : -1,
            autoDispose: false,
          );
          addTearDown(computed.dispose);
          expect(computed.value, 0);
          final seen = <int>[];

          batch(() {
            s.update('x', (current) {
              s['x'] = 1;
              final survivor = Effect(() => seen.add(s.value['x']!));
              addTearDown(survivor.dispose);
              gate.value = false;
              expect(computed.value, -1);
              expect(s.listenerCount, 1);
              gate.value = true;
              expect(computed.value, 1);
              expect(s.listenerCount, 2);
              s
                ..['x'] = 2
                ..value = {'x': 1};
              return current;
            });
          });

          expect(seen, [1]);
          expect(computed.value, 1);
        });

        for (final (incumbent, repeat, distinct) in [
          (true, false, false),
          (false, true, false),
          (false, true, true),
        ]) {
          test(
            'surviving maps agree by contents (history: $history, '
            'opaque: $opaque, incumbent: $incumbent, distinct: $distinct)',
            () {
              final backing = {'x': 0};
              final s = MapSignal(
                opaque ? MapView(backing) : backing,
                equals: true,
                trackPreviousValue: history,
              );
              addTearDown(s.dispose);
              var first = incumbent ? Effect(() => s['x']) : null;
              final seen = <int>[];
              final later = <int>[];
              final laterValue = distinct ? 4 : 1;

              batch(() {
                s.update('x', (current) {
                  if (!incumbent) {
                    s['x'] = 2;
                    first = Effect(() => s['x']);
                  }
                  s['x'] = 1;
                  final survivor = Effect(() => seen.add(s['x']!));
                  addTearDown(survivor.dispose);
                  if (repeat) {
                    s
                      ..['x'] = 3
                      ..['x'] = laterValue;
                    final another = Effect(() => later.add(s['x']!));
                    addTearDown(another.dispose);
                  }
                  first!.dispose();
                  s
                    ..['x'] = 2
                    ..value = {'x': 1};
                  return current;
                });
              });

              expect(seen, [1, if (distinct) 1]);
              expect(later, [if (repeat) laterValue, if (distinct) 1]);
            },
          );
        }

        for (final (keepAnchor, reread) in [
          (false, false),
          (true, false),
          (false, true),
        ]) {
          test('surviving observers keep their own observed contents '
              '(history: $history, opaque: $opaque, anchor: $keepAnchor, '
              'reread: $reread)', () {
            final backing = {'x': 0};
            final s = MapSignal(
              opaque ? MapView(backing) : backing,
              equals: true,
              trackPreviousValue: history,
            );
            addTearDown(s.dispose);
            final seen = <int>[];
            final alsoSeen = <int>[];
            final anchorValues = <int>[];

            batch(() {
              s.update('x', (current) {
                s['x'] = 1;
                final first = Effect(() => s['x']);
                if (keepAnchor) {
                  final anchor = Effect(() => anchorValues.add(s['x']!));
                  addTearDown(anchor.dispose);
                }
                s['x'] = 0;
                final survivor = Effect(() => seen.add(s['x']!));
                addTearDown(survivor.dispose);
                final alsoSurvives = Effect(() => alsoSeen.add(s['x']!));
                addTearDown(alsoSurvives.dispose);
                first.dispose();
                if (reread) {
                  s
                    ..['x'] = 2
                    ..['x'] = 0;
                  survivor.run();
                }
                s['x'] = 2;
                if (reread) survivor.run();
                s.value = {'x': 0};
                return current;
              });
            });

            expect(seen, [
              0,
              if (reread) ...[0, 2],
              if (keepAnchor || reread) 0,
            ]);
            expect(alsoSeen, [0, if (keepAnchor || reread) 0]);
            expect(anchorValues, [
              if (keepAnchor) ...[1, 0],
            ]);
          });
        }
      }

      test('a tracked read sees writes made by its equality check '
          '(history: $history)', () {
        late final MapSignal<String, _CountedMapValue> s;
        _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
        var write = false;
        final original = _CountedMapValue(
          0,
          () {},
          onEquals: () {
            if (!write) return;
            write = false;
            s['x'] = valueOf(2);
          },
        );
        s = MapSignal(
          {'x': original},
          equals: true,
          trackPreviousValue: history,
        );
        addTearDown(s.dispose);
        final seen = <int>[];
        final effect = Effect(() => seen.add(s.value['x']!.key));
        addTearDown(effect.dispose);

        batch(() {
          s.update('x', (current) {
            s
              ..['x'] = valueOf(1)
              ..['x'] = valueOf(0);
            write = true;
            effect.run();
            s.value = {'x': valueOf(0)};
            return current;
          });
        });

        expect(seen, [0, 2, 0]);
      });
    }

    for (final restore in [false, true]) {
      test('an opaque write can invalidate a saved slot comparison '
          '(restored: $restore)', () {
        final s = MapSignal(
          {'x': 0, 'y': 0},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final incumbent = Effect(() => s.value['x']);
        addTearDown(incumbent.dispose);
        final seen = <(int, int)>[];

        batch(() {
          s.update('x', (current) {
            s['x'] = 1;
            final survivor = Effect(() {
              final map = s.value;
              seen.add((map['x']!, map['y']!));
            });
            addTearDown(survivor.dispose);
            incumbent.dispose();
            s.addAll({'y': 2});
            if (restore) s.addAll({'y': 0});
            survivor.run();
            s
              ..['x'] = 2
              ..value = {'x': 1, 'y': 0};
            return current;
          });
        });

        final reread = restore ? 0 : 2;
        expect(seen, [(1, 0), (1, reread), if (!restore) (1, 0)]);
      });
    }

    test('a replacement preserves the observed presence of nullable slots', () {
      final s = MapSignal(
        <String, int?>{'outer': 0, 'removed': 1},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final incumbent = Effect(() => s.value['outer']);
      addTearDown(incumbent.dispose);
      final seen = <(bool, bool)>[];

      batch(() {
        s.update('outer', (current) {
          s
            ..['added'] = null
            ..remove('removed');
          final survivor = Effect(() {
            final map = s.value;
            seen.add((map.containsKey('added'), map.containsKey('removed')));
          });
          addTearDown(survivor.dispose);
          incumbent.dispose();
          s
            ..remove('added')
            ..['removed'] = 1
            ..value = {'outer': 0, 'added': null};
          return current;
        });
      });

      expect(seen, [(true, false)]);
    });

    test('an incumbent that reorders its dependencies keeps delivery', () {
      final s = MapSignal({'x': 0}, equals: true, trackPreviousValue: false);
      addTearDown(s.dispose);
      final other = Signal(0);
      addTearDown(other.dispose);
      var mapFirst = false;
      final seen = <int>[];
      final incumbent = Effect(() {
        if (!mapFirst) other.value;
        seen.add(s.value['x']!);
        if (mapFirst) other.value;
      });
      addTearDown(incumbent.dispose);

      batch(() {
        s.update('x', (current) {
          s['x'] = 1;
          mapFirst = true;
          incumbent.run();
          s
            ..['x'] = 2
            ..value = {'x': 1};
          return current;
        });
      });

      expect(seen, [0, 1, 1]);
    });

    for (final reenter in [false, true]) {
      test('surviving map comparison handles a user hash callback '
          '(reentrant: $reenter)', () {
        _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
        final s = MapSignal(
          {'x': valueOf(0)},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        var check = false;
        final observed = _CountedMapValue(1, () {
          if (!check) return;
          check = false;
          if (!reenter) throw StateError('cannot compare observed maps');
          s
            ..value = {'x': valueOf(9)}
            ..value;
        });
        final first = Effect(() => s.value['x']);
        final seen = <int>[];
        final later = <int>[];

        batch(() {
          s.update('x', (current) {
            s['x'] = observed;
            final survivor = Effect(() => seen.add(s.value['x']!.key));
            addTearDown(survivor.dispose);
            s
              ..['x'] = valueOf(3)
              ..['x'] = valueOf(1);
            final another = Effect(() => later.add(s.value['x']!.key));
            addTearDown(another.dispose);
            first.dispose();
            s['x'] = valueOf(2);
            check = true;
            s.value = {'x': valueOf(1)};
            if (reenter) expect(s.shouldUpdate(), isFalse);
            return current;
          });
        });

        expect(check, isFalse);
        final finalValue = reenter ? 9 : 1;
        expect(seen, [1, finalValue]);
        expect(later, seen);
      });
    }

    for (final reentrantRead in [false, true]) {
      test('a comparison can replace a map during a tracked read '
          '(reentrant read: $reentrantRead)', () {
        _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
        late final MapSignal<String, _CountedMapValue> s;
        late final Effect incumbent;
        var replace = false;
        final original = _CountedMapValue(
          0,
          () {},
          onEquals: () {
            if (!replace) return;
            replace = false;
            if (reentrantRead) incumbent.run();
            s.value = {'x': valueOf(0)};
          },
        );
        s = MapSignal(
          {'x': original},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final seen = <int>[];
        incumbent = Effect(() => seen.add(s.value['x']!.key));
        addTearDown(incumbent.dispose);

        batch(() {
          s.update('x', (current) {
            s['x'] = valueOf(1);
            replace = true;
            if (reentrantRead) {
              Effect(() => s.value['x']).dispose();
            } else {
              incumbent.run();
            }
            return current;
          });
        });

        expect(seen, [0, 1, 0]);
      });
    }

    test('a failed observation comparison keeps deferred delivery', () {
      var failHash = false;
      final original = _CountedMapValue(0, () {
        if (!failHash) return;
        failHash = false;
        throw StateError('cannot compare the intermediate map');
      });
      final intermediate = _CountedMapValue(1, () {});
      final s = MapSignal(
        {'x': original},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final seen = <int>[];
      final incumbent = Effect(() => seen.add(s.value['x']!.key));
      addTearDown(incumbent.dispose);

      Iterable<MapEntry<String, _CountedMapValue>> writes() sync* {
        s['x'] = intermediate;
        yield MapEntry('x', intermediate);
      }

      batch(() {
        s.update('x', (current) {
          s.addEntries(writes());
          failHash = true;
          Effect(() => s.value['x']).dispose();
          s.value = {'x': original};
          return current;
        });
      });

      expect(failHash, isFalse);
      expect(seen, [0, 0]);
    });

    test('a tracked point read after a nested write does not scan the map', () {
      var hashCalls = 0;
      _HashKey value(int hash) => _HashKey(() {
        hashCalls++;
        return hash;
      });

      final s = MapSignal(
        {for (var i = 0; i < 10000; i++) i: value(i)},
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final next = value(-1);
      s.update(0, (old) {
        s[1] = next;
        final effect = Effect(() => s.value[1]);
        addTearDown(effect.dispose);
        return old;
      });

      expect(s.value[1], same(next));
      expect(hashCalls, 0);
    });

    test('a subscriber added after a nested restoration sees one value', () {
      final s = MapSignal(
        {'a': 1, 'b': 1},
        equals: true,
        trackPreviousValue: false,
      );
      final w = watch(s);
      final seen = <int?>[];

      batch(() {
        s.update('a', (value) {
          s
            ..['b'] = 2
            ..['b'] = 1;
          final effect = Effect(() => seen.add(s.value['b']));
          addTearDown(effect.dispose);
          s
            ..value = {'a': 2, 'b': 1}
            ..value = {'a': 1, 'b': 1};
          return value;
        });
      });

      expect(w.effectReruns, 0);
      expect(seen, [1]);
    });

    for (final readIntermediate in [false, true]) {
      test('the first subscriber uses the current map after an incumbent '
          'detaches (read intermediate: $readIntermediate)', () {
        final s = MapSignal(
          {'a': 1, 'b': 1},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final incumbent = Effect(() => s.value['b']);
        addTearDown(incumbent.dispose);
        final seen = <int?>[];

        batch(() {
          s.update('a', (a) {
            s.addAll({'b': 2});
            if (readIntermediate) incumbent.run();
            incumbent.dispose();
            final successor = Effect(() => seen.add(s.value['b']));
            addTearDown(successor.dispose);
            s
              ..value = {'a': 3, 'b': 2}
              ..value = {'a': 1, 'b': 2};
            return a;
          });
        });

        expect(seen, [2]);
      });
    }

    test('a synchronous replacement does not scan the outgoing map', () {
      final backing = _CountingMap(100000);
      final s = MapSignal(backing, equals: true, trackPreviousValue: false);
      final lengths = <int>[];
      final effect = Effect(() => lengths.add(s.value.length));
      addTearDown(effect.dispose);
      final scans = backing.scans;

      s.update(0, (_) {
        s.value = {0: 1};
        return 1;
      });

      expect(lengths, [100000, 1]);
      expect(backing.scans, scans);
    });

    for (final nested in ['update', 'putIfAbsent', 'update ifAbsent']) {
      test('a synchronous replacement inside a nested $nested does not scan '
          'the outgoing map', () {
        final backing = _CountingMap(100000);
        final s = MapSignal(backing, equals: true, trackPreviousValue: false);
        addTearDown(s.dispose);
        final lengths = <int>[];
        final effect = Effect(() => lengths.add(s.value.length));
        addTearDown(effect.dispose);

        int replace() {
          s.value = {0: 1};
          return 1;
        }

        switch (nested) {
          case 'putIfAbsent':
            s.update(0, (value) {
              s.putIfAbsent(-1, replace);
              return value;
            });
          case 'update ifAbsent':
            s.update(0, (value) {
              s.update(-1, (value) => value, ifAbsent: replace);
              return value;
            });
          default:
            s.putIfAbsent(-1, () {
              s.update(0, (_) => replace());
              return -1;
            });
        }

        expect(lengths, [100000, 1]);
        expect(backing.scans, 0);
      });
    }

    for (final removes in [false, true]) {
      final operation = removes ? 'removeWhere' : 'updateAll';
      test('synchronous replacement in nested $operation adds no scan', () {
        final backing = _CountingMap(100000);
        final s = MapSignal(backing, equals: true, trackPreviousValue: false);
        addTearDown(s.dispose);
        final lengths = <int>[];
        final effect = Effect(() => lengths.add(s.value.length));
        addTearDown(effect.dispose);

        void replace(int key) {
          if (key != 0) return;
          s.update(0, (value) {
            s.value = {0: 1};
            return value;
          });
        }

        s.update(0, (value) {
          if (removes) {
            s.removeWhere((key, value) {
              replace(key);
              return false;
            });
          } else {
            s.updateAll((key, value) {
              replace(key);
              return value;
            });
          }
          return value;
        });

        expect(lengths, [100000, 1]);
        expect(backing.scans, removes ? 0 : 1);
      });
    }

    test('an equal nested update stores the new value and notifies', () {
      final old = _CountedMapValue(2, () {});
      final next = _CountedMapValue(2, () {});
      final s = MapSignal({'a': old, 'b': old}, equals: true);
      final w = watch(s);

      s.update('a', (value) {
        s.update('b', (_) => next);
        return value;
      });

      expect(w.effectReruns, 1);
      expect(s.previousValue!['b'], same(old));
      expect(s.value['b'], same(next));
    });

    for (final history in [false, true]) {
      for (final opaque in [false, true]) {
        test('an equivalent nested point write preserves a later replacement '
            '(history: $history, opaque: $opaque)', () {
          _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
          final backing = {'a': valueOf(0)};
          final s = MapSignal(
            opaque ? MapView(backing) : backing,
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final seen = <int>[];
          final effect = Effect(() => seen.add(s.value['a']!.key));
          addTearDown(effect.dispose);

          batch(() {
            s.update('a', (value) {
              s
                ..update('a', (current) => valueOf(current.key))
                ..value = {'a': valueOf(1)};
              return valueOf(1);
            });
            expect(seen, [0]);
          });

          expect(seen, [0, 1]);
          expect(s.untrackedPreviousValue?['a']?.key, history ? 0 : null);
        });
      }

      for (final finalValue in [0, 2]) {
        test('reentrant equality keeps the point write visible '
            '(history: $history, final value: $finalValue)', () {
          _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
          late final MapSignal<String, _CountedMapValue> s;
          late Effect temporary;
          var reenter = false;
          final temporaryValues = <int>[];
          final original = _CountedMapValue(
            0,
            () {},
            onEquals: () {
              if (!reenter) return;
              reenter = false;
              s['x'] = valueOf(2);
              temporary = Effect(() => temporaryValues.add(s.value['x']!.key));
            },
          );
          s = MapSignal(
            {'x': original},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final incumbent = Effect(() => s.value['x']);
          addTearDown(incumbent.dispose);
          final seen = <int>[];

          batch(() {
            s.update('x', (current) {
              reenter = true;
              s.update('x', (_) => valueOf(0));
              final survivor = Effect(() => seen.add(s.value['x']!.key));
              addTearDown(survivor.dispose);
              incumbent.dispose();
              temporary.dispose();
              s
                ..['x'] = valueOf(3)
                ..value = {'x': valueOf(finalValue)};
              return current;
            });
          });

          expect(temporaryValues, [2]);
          expect(seen, [0, if (finalValue != 0) finalValue]);
        });
      }

      for (final callback in [false, true]) {
        test('a point write refreshes its slot after reentrant equality '
            '(history: $history, callback: $callback)', () {
          _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
          late final MapSignal<String, _CountedMapValue> s;
          var reenter = false;
          var assigning = false;
          var repeatedComparisons = 0;
          var updateCalls = 0;
          final first = <int>[];
          final second = <int>[];
          final restored = _CountedMapValue(
            0,
            () {},
            onEquals: () {
              if (assigning) repeatedComparisons++;
            },
          );
          final original = _CountedMapValue(
            2,
            () {},
            onEquals: () {
              if (!reenter) return;
              reenter = false;
              s.updateAll((_, _) => restored);
              final effect = Effect(() => first.add(s.value['x']!.key));
              addTearDown(effect.dispose);
            },
          );
          s = MapSignal(
            {'x': original},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);

          batch(() {
            s.update('x', (current) {
              reenter = true;
              assigning = true;
              if (callback) {
                s.update('x', (_) {
                  updateCalls++;
                  return valueOf(2);
                });
              } else {
                s['x'] = valueOf(2);
              }
              assigning = false;
              final effect = Effect(() => second.add(s.value['x']!.key));
              addTearDown(effect.dispose);
              s
                ..['x'] = valueOf(3)
                ..value = {'x': valueOf(0)};
              return current;
            });
          });

          expect(first, [0, 0]);
          expect(second, [2, 0]);
          expect(repeatedComparisons, 0);
          expect(updateCalls, callback ? 1 : 0);
          expect(
            s.untrackedPreviousValue?['x'],
            same(history ? original : null),
          );
        });
      }

      test('a slot assignment follows the backing selected by equality '
          '(history: $history)', () {
        _CountedMapValue valueOf(int key) => _CountedMapValue(key, () {});
        late final MapSignal<String, _CountedMapValue> s;
        var reenter = false;
        final replacementValue = valueOf(2);
        final replacement = {'outer': valueOf(0), 'key': replacementValue};
        final original = _CountedMapValue(
          0,
          () {},
          onEquals: () {
            if (!reenter) return;
            reenter = false;
            s.value = replacement;
          },
        );
        s = MapSignal(
          {'outer': valueOf(0), 'key': original},
          equals: true,
          trackPreviousValue: history,
        );
        addTearDown(s.dispose);
        final seen = <int>[];
        final effect = Effect(() => seen.add(s.value['key']!.key));
        addTearDown(effect.dispose);
        final assigned = valueOf(0);

        batch(() {
          s.update('outer', (current) {
            reenter = true;
            s['key'] = assigned;
            return current;
          });
        });

        expect(s.untrackedValue, same(replacement));
        expect(s.untrackedValue['key'], same(assigned));
        expect(
          s.untrackedPreviousValue?['key'],
          same(history ? replacementValue : null),
        );
        expect(seen, [0, 0]);
      });
    }

    test('a deferred replacement outside a batch updates a computed', () {
      final s = MapSignal({'a': 1}, equals: true, trackPreviousValue: false);
      final selected = Computed(() => s.value['a']);
      addTearDown(selected.dispose);
      expect(selected.value, 1);

      s.update('a', (_) {
        s.value = {'a': 2};
        return 2;
      });

      expect(selected.value, 2);
    });

    for (final key in ['a', 'absent']) {
      test('replacement bookkeeping does not track map reads for $key', () {
        final mapDependency = Signal(0, autoDispose: false);
        final callbackDependency = Signal(2, autoDispose: false);
        final backing = _ReactiveMapView({'a': 1}, mapDependency);
        final s = MapSignal(backing, equals: true, trackPreviousValue: false);
        var runs = 0;
        final effect = Effect(() {
          if (++runs != 1) return;

          int replace() {
            final next = callbackDependency.value;
            s.value = {'a': next, 'b': 3};
            return next;
          }

          s.update(key, (_) => replace(), ifAbsent: replace);
        });
        addTearDown(effect.dispose);

        mapDependency.value++;
        expect(runs, 1);
        callbackDependency.value++;
        expect(runs, 2);
      });
    }

    test(
      'a computed can read a pending replacement before a batched update',
      () {
        final s = MapSignal({'a': 1}, equals: true, trackPreviousValue: false);
        addTearDown(s.dispose);
        final selected = Computed(() => s.value['a']);
        addTearDown(selected.dispose);
        final changed = <int?>[];
        final effect = Effect(() => changed.add(selected.value));
        addTearDown(effect.dispose);

        final pending = {'a': 2};
        batch(() {
          s.value = pending;
          expect(selected.value, 2);
          s.update('a', (_) {
            s.value = {'a': 3};
            return 3;
          });
          expect(pending, {'a': 3});
          expect(selected.value, 3);
          expect(changed, [1]);
        });

        expect(changed, [1, 3]);
      },
    );

    test('a replacement in a nested update notifies at batch flush', () {
      final s = MapSignal({'a': 1, 'b': 1}, equals: true);
      final w = watch(s);

      batch(() {
        s.update('b', (value) {
          s.update('a', (_) {
            s.value = {'a': 2, 'b': 1};
            return 2;
          });
          return value;
        });

        expect(w.effectReruns, 0);
      });

      expect(w.effectReruns, 1);
      expect(w.calls, [
        [
          {'a': 1, 'b': 1},
          {'a': 2, 'b': 1},
        ],
      ]);
    });

    for (final history in [false, true]) {
      for (final removes in [false, true]) {
        final operation = removes ? 'removeWhere' : 'updateAll';
        test(
          'a nested update read sees earlier $operation '
          'writes (history: $history)',
          () {
            final original = {'a': 1, 'b': 1, 'c': 1};
            final backing = Map.of(original);
            final s = MapSignal(
              backing,
              equals: true,
              trackPreviousValue: history,
            );
            watch(s);
            final seen = <int?>[];
            final observer = Effect(() => seen.add(s.value['a']));
            addTearDown(observer.dispose);
            int? intermediate;

            int readAndRestore(int value) {
              intermediate = backing['a'];
              observer.run();
              s
                ..value = {...original, 'a': 3}
                ..value = original;
              return value;
            }

            batch(() {
              if (removes) {
                s.removeWhere((key, value) {
                  if (key == 'b') s.update(key, readAndRestore);
                  return key == 'a';
                });
              } else {
                s.updateAll((key, value) {
                  if (key == 'b') return s.update(key, readAndRestore);
                  return key == 'a' ? 2 : value;
                });
              }
            });

            expect(s.untrackedValue, original);
            // Some backings apply accepted removals after all predicates run.
            expect(seen, [1, intermediate, if (intermediate != 1) 1]);
          },
        );
      }

      for (final restored in [1, 2]) {
        test('a first observer in updateAll sees the final point value '
            '(history: $history, final: $restored)', () {
          final s = MapSignal(
            {'a': 1, 'b': 1},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final seen = <int?>[];

          batch(() {
            s.updateAll((key, value) {
              if (key == 'a') {
                s['b'] = 2;
                final observer = Effect(() => seen.add(s.value['b']));
                addTearDown(observer.dispose);
                s.update(key, (value) {
                  s
                    ..value = {'a': 3, 'b': restored}
                    ..value = {'a': 1, 'b': restored};
                  return value;
                });
              }
              return value;
            });
          });

          expect(seen, [2, if (restored != 2) restored]);
        });
      }

      test('updateAll tracks a return that overwrites a nested same-key '
          'write (history: $history)', () {
        final s = MapSignal(
          {'a': 2, 'b': 1},
          equals: true,
          trackPreviousValue: history,
        );
        addTearDown(s.dispose);
        final seen = <int?>[];
        final observer = Effect(() => seen.add(s.value['a']));
        addTearDown(observer.dispose);

        batch(() {
          s.update('b', (value) {
            s['a'] = 1;
            s.updateAll((key, value) {
              if (key == 'a') {
                s['a'] = 2;
                observer.run();
              } else {
                observer.run();
                s.update(key, (value) {
                  s.value = {'a': 2, 'b': 1};
                  return value;
                });
              }
              return value;
            });
            return value;
          });
        });

        expect(seen, [2, 2, 1, 2]);
      });

      for (final restores in [false, true]) {
        for (final removes in [false, true]) {
          test('nested update inside ${removes ? 'removeWhere' : 'updateAll'} '
              'compares with the committed map (history: $history, '
              'restores: $restores)', () {
            final initial = {'a': 1, 'b': 1, 'c': 1};
            final backing = Map.of(initial);
            final s = MapSignal(
              backing,
              equals: true,
              trackPreviousValue: history,
            );
            addTearDown(s.dispose);
            final seen = <Map<String, int>>[];
            final effect = Effect(() => seen.add(Map.of(s.value)));
            addTearDown(effect.dispose);
            final outgoing = removes ? {'b': 2} : {'a': 2, 'b': 2, 'c': 2};
            final next = restores ? initial : outgoing;

            void replace() {
              s.update('b', (_) {
                s.value = next;
                return 2;
              });
            }

            batch(() {
              if (removes) {
                s.removeWhere((key, _) {
                  if (key == 'b') {
                    s['c'] = 2;
                    replace();
                  }
                  return key != 'b';
                });
              } else {
                s.updateAll((key, _) {
                  if (key == 'b') replace();
                  return 2;
                });
              }
              expect(seen, [initial]);
            });

            expect(backing, outgoing);
            expect(s.untrackedValue, next);
            expect(seen, [initial, if (!restores) next]);
            expect(s.untrackedPreviousValue, history ? initial : null);
            expect(
              s.untrackedPreviousValue?.keys,
              history ? initial.keys : null,
            );
          });
        }
      }

      test('nested update inside putIfAbsent compares with the committed '
          'map (history: $history)', () {
        final s = MapSignal(
          {'a': 1},
          equals: true,
          trackPreviousValue: history,
        );
        final w = watch(s);

        batch(() {
          s.putIfAbsent('b', () {
            s.update('a', (_) {
              s.value = {'a': 2, 'b': 3};
              return 2;
            });
            return 3;
          });
          expect(w.effectReruns, 0);
        });

        expect(s.untrackedValue, {'a': 2, 'b': 3});
        expect(w.effectReruns, 1);
      });

      for (final alreadyObserved in [false, true]) {
        test('a batch can restore the first observed stable write '
            '(history: $history, already observed: $alreadyObserved)', () {
          final s = MapSignal(
            <String, int?>{'a': 1, 'b': 1},
            equals: true,
            trackPreviousValue: history,
          );
          addTearDown(s.dispose);
          final seen = <(bool, int?)>[];
          final earlier = <int?>[];
          if (alreadyObserved) {
            final effect = Effect(() => earlier.add(s.value['b']));
            addTearDown(effect.dispose);
          }

          batch(() {
            s.update('a', (a) {
              s['b'] = null;
              final effect = Effect(() {
                final value = s.value;
                seen.add((value.containsKey('b'), value['b']));
              });
              addTearDown(effect.dispose);
              s
                ..value = {'a': 3, 'b': null}
                ..value = {'a': 1, 'b': null};
              return a;
            });
            expect(seen, [(true, null)]);
          });

          expect(earlier, [
            if (alreadyObserved) ...[1, null],
          ]);
          expect(seen, [(true, null), if (alreadyObserved) (true, null)]);
        });
      }
    }

    test('a subscriber during removeWhere sees a restored entry at flush', () {
      final backing = {'a': 1, 'b': 1};
      final s = MapSignal(backing, equals: true, trackPreviousValue: false);
      addTearDown(s.dispose);
      final earlier = Effect(() => s.value.length);
      addTearDown(earlier.dispose);
      final seen = <bool>[];
      late bool presentDuringRemoval;

      batch(() {
        s.removeWhere((key, _) {
          if (key == 'a') return true;
          // The backing can remove 'a' now or after all predicates return.
          presentDuringRemoval = backing.containsKey('a');
          final observer = Effect(() => seen.add(s.value.containsKey('a')));
          addTearDown(observer.dispose);
          s.update('b', (value) {
            s
              ..value = {'a': 3, 'b': 1}
              ..value = {'a': 1, 'b': 1};
            return value;
          });
          return false;
        });
        expect(seen, [presentDuringRemoval]);
      });

      expect(backing, {'b': 1});
      expect(s.untrackedValue, {'a': 1, 'b': 1});
      expect(seen, [presentDuringRemoval, if (!presentDuringRemoval) true]);
    });

    for (final next in [1, 2]) {
      test('first observation keeps the slot of an in-progress update '
          '(final value: $next)', () {
        final s = MapSignal(
          {'a': 1, 'b': 1, 'c': 1},
          equals: true,
          trackPreviousValue: false,
        );
        addTearDown(s.dispose);
        final seen = <int?>[];

        batch(() {
          s.update('a', (a) {
            s['c'] = 2;
            s.update('b', (_) {
              final effect = Effect(() => seen.add(s.value['b']));
              addTearDown(effect.dispose);
              s
                ..value = {'a': 3, 'b': next, 'c': 2}
                ..value = {'a': 1, 'b': next, 'c': 2};
              return 2;
            });
            return a;
          });
        });

        expect(seen, [1, if (next != 1) next]);
      });
    }

    test('a replacement notifies after a nested write repairs a cast map', () {
      final backing = <String, Object>{'a': 1, 'bad': 'x'};
      final s = MapSignal(
        backing.cast<String, int>(),
        equals: true,
        trackPreviousValue: false,
      );
      addTearDown(s.dispose);
      final seen = <int?>[];
      final effect = Effect(() => seen.add(s.value['a']));
      addTearDown(effect.dispose);

      batch(() {
        s.update('a', (_) {
          s
            ..addAll({'bad': 3})
            ..value = {'a': 2, 'bad': 3};
          return 2;
        });
        expect(seen, [1]);
      });

      expect(seen, [1, 2]);
    });

    test('a replacement in a nested update delivers an earlier ancestor '
        'write', () {
      final s = MapSignal({'a': 1, 'b': 1, 'c': 1}, equals: true);
      final w = watch(s);

      batch(() {
        s.update('c', (c) {
          s['b'] = 2;
          s.update('b', (b) {
            s.update('a', (_) {
              s
                ..value = {'a': 2, 'b': 2, 'c': 1}
                ..value = {'a': 1, 'b': 2, 'c': 1};
              return 1;
            });
            return b;
          });
          return c;
        });
      });

      expect(w.effectReruns, 1);
      expect(w.calls, [
        [
          {'a': 2, 'b': 2, 'c': 1},
          {'a': 1, 'b': 2, 'c': 1},
        ],
      ]);
    });

    test(
      'a batched replacement keeps the earlier committed map for comparison',
      () {
        final s = MapSignal({'a': 1}, equals: true, trackPreviousValue: false);
        final w = watch(s);

        batch(() {
          s.value = {'a': 2};
          s.update('a', (_) {
            s.value = {'a': 1};
            return 2;
          });
        });

        expect(s.untrackedValue, {'a': 1});
        expect(w.effectReruns, 0);
      },
    );

    test('a batched replacement delivers a nested write made before it', () {
      final s = MapSignal(
        {'a': 1, 'b': 1},
        equals: true,
        trackPreviousValue: false,
      );
      final w = watch(s);

      batch(() {
        s.update('a', (_) {
          s
            ..['b'] = 2
            ..value = {'a': 3, 'b': 2}
            ..value = {'a': 1, 'b': 2};
          return 2;
        });
      });

      expect(s.untrackedValue, {'a': 1, 'b': 2});
      expect(w.effectReruns, 1);
    });

    test('a custom comparator compares the original backing map', () {
      final backing = {'a': 1};
      final equivalent = {'a': 3};
      final s = MapSignal(
        backing,
        comparator: (old, next) =>
            identical(old, backing) && identical(next, equivalent),
        trackPreviousValue: false,
      );
      final w = watch(s);

      batch(() {
        s.update('a', (_) {
          s
            ..value = {'a': 2}
            ..value = equivalent;
          return 2;
        });
      });

      expect(s.untrackedValue, same(equivalent));
      expect(w.effectReruns, 0);
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
      test('update without history does not see a raw write through '
          '$name to another key', () {
        final s = MapSignal({'a': 1, 'b': 2}, trackPreviousValue: false);
        final w = watch(s);

        s.update('a', (v) {
          view(s)['b'] = 3;
          return v;
        });

        expect(s.untrackedValue, {'a': 1, 'b': 3});
        expect(w.calls, isEmpty);
        expect(w.effectReruns, 0);
      });
    }

    test('an assignment during updateAll keeps the map from before the '
        'mutation as previous', () {
      final s = MapSignal({'a': 1, 'b': 2});
      final w = watch(s);

      s.updateAll((key, value) {
        if (key == 'a') return 11;
        s.value = {'c': 3};
        return value;
      });

      expect(s.untrackedValue, {'c': 3});
      expect(s.untrackedPreviousValue, {'a': 1, 'b': 2});
      expect(w.calls, [
        [
          {'a': 1, 'b': 2},
          {'c': 3},
        ],
      ]);
    });

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

    for (final history in [false, true]) {
      final inputs = <String, void Function(MapSignal<String, int>)>{
        'addAll': (s) => s.addAll(_ThrowAfterFirstMap()),
        'addEntries from a list': (s) => s.addEntries(_ThrowAfterFirstList()),
      };
      for (final MapEntry(key: name, value: write) in inputs.entries) {
        test('$name from an input that throws after one entry notifies the '
            'partial change, history $history', () {
          final s = MapSignal({'a': 1}, trackPreviousValue: history);
          addTearDown(s.dispose);
          var runs = 0;
          final effect = Effect(() {
            s.value;
            runs++;
          });
          addTearDown(effect.dispose);

          expect(() => write(s), throwsStateError);

          expect(s.untrackedValue, {'a': 1, 'b': 2});
          expect(runs, 2);
        });
      }
    }

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

    test('a batched update can replace a cast map with a shorter map', () {
      final s = MapSignal(castMap(), equals: true, trackPreviousValue: false);
      addTearDown(s.dispose);
      final changed = <String?>[];
      final effect = Effect(() => changed.add(s.value['a']));
      addTearDown(effect.dispose);

      batch(() {
        s.update('a', (_) {
          s.value = {'a': 'y'};
          return 'y';
        });
      });

      expect(s.untrackedValue, {'a': 'y'});
      expect(changed, ['x', 'y']);
    });

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

    test('addAll over an unreadable value of a cast map notifies once', () {
      final backing = <String, Object>{'unread': 42}.cast<String, String>();
      final map = MapSignal<String, String>(backing, trackPreviousValue: false);
      addTearDown(map.dispose);
      var runs = 0;
      final effect = Effect(() {
        map.value;
        runs++;
      });
      addTearDown(effect.dispose);

      map.addAll({'unread': 'ok'});

      expect(map.untrackedValue['unread'], 'ok');
      expect(runs, 2);
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

  group('adversarial round 2', () {
    for (final history in [false, true]) {
      test('addEntries from a list view that reruns its source, history '
          '$history', () {
        final s = MapSignal({'a': 0, 'b': 0}, trackPreviousValue: history);
        addTearDown(s.dispose);
        var calls = 0;
        final effect = Effect(() {
          s.value;
          calls++;
        });
        addTearDown(effect.dispose);
        var visits = 0;
        final entries = UnmodifiableListView(
          [0].map((_) => MapEntry(++visits == 1 ? 'a' : 'b', 1)),
        );

        s.addEntries(entries);

        expect(calls - 1, 1);
        expect(s.untrackedValue, {'a': 1, 'b': 0});
        if (history) expect(s.untrackedPreviousValue, {'a': 0, 'b': 0});
      });
    }

    test('a throwing effect does not skip the observers', () {
      final observer = _CountingObserver();
      final s = ListSignal<int>([]);
      addTearDown(s.dispose);
      final effect = Effect(() {
        if (s.value.isNotEmpty) throw StateError('effect');
      });
      addTearDown(effect.dispose);
      SolidartConfig.observers.add(observer);
      addTearDown(() => SolidartConfig.observers.remove(observer));
      Iterable<int> partial() sync* {
        yield 1;
        throw StateError('mutation');
      }

      final zone = <Object>[];
      Object? thrown;
      runZonedGuarded(() {
        try {
          s.addAll(partial());
        } on Object catch (error) {
          thrown = error;
        }
      }, (error, _) => zone.add(error));

      expect((thrown! as StateError).message, 'mutation');
      expect(observer.updates, 1);
      expect(zone.map((e) => (e as StateError).message), ['effect']);
    });

    test('fillRange with a reversed range throws like the plain list', () {
      final backing = List<int>.unmodifiable([1]);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      Object? plain;
      Object? signal;
      try {
        backing.fillRange(1, 0, 2);
      } on Object catch (error) {
        plain = error;
      }
      try {
        s.fillRange(1, 0, 2);
      } on Object catch (error) {
        signal = error;
      }

      expect(signal.runtimeType, plain.runtimeType);
    });

    test('replaceRange that only removes reads no slot before the write', () {
      final plain = _CountingList(100)..replaceRange(0, 100, const []);
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      backing.reads = 0;

      s.replaceRange(0, 100, const []);

      expect(backing.reads, plain.reads);
      expect(s.untrackedValue, isEmpty);
    });
  });

  group('adversarial #213 round 4', () {
    for (final (name, backing) in <(String, List<int> Function())>[
      ('typed list', () => Uint8List.fromList([0, 17, 2])),
      (
        'cast view of a typed list',
        () => Uint8List.fromList([0, 17, 2]).cast<int>(),
      ),
    ]) {
      test('a fill that a $name converts keeps exact history', () {
        final s = ListSignal<int>([])..value = backing();
        addTearDown(s.dispose);
        var calls = 0;
        s.addListener(() => calls++);

        s[2] = 9;
        // 256 is stored as 0, so slot 0 keeps its value and slot 1 changes.
        s.fillRange(0, 2, 256);

        expect(calls, 2);
        expect(s.untrackedValue, [0, 0, 9]);
        expect(s.untrackedPreviousValue, [0, 17, 9]);
      });
    }

    test('a fill that a typed list converts to the stored values does not '
        'notify', () {
      final s = ListSignal<int>([])..value = Uint8List.fromList([0, 0, 5]);
      addTearDown(s.dispose);
      var calls = 0;
      s
        ..addListener(() => calls++)
        ..fillRange(0, 2, 256);

      expect(calls, 0);
      expect(s.untrackedValue, [0, 0, 5]);
    });

    test('fillRange on an unmodifiable typed list throws and does not '
        'notify', () {
      final s = ListSignal<int>([])..value = Uint8List(2).asUnmodifiableView();
      addTearDown(s.dispose);
      final previous = s.untrackedPreviousValue;
      var calls = 0;
      s.addListener(() => calls++);

      expect(() => s.fillRange(0, 2, 1), throwsUnsupportedError);

      expect(calls, 0);
      expect(s.untrackedPreviousValue, same(previous));
    });

    test('fillRange on an unmodifiable list throws and does not notify', () {
      final s = ListSignal<int>([])..value = List<int>.unmodifiable([1, 2]);
      addTearDown(s.dispose);
      final previous = s.untrackedPreviousValue;
      var calls = 0;
      s.addListener(() => calls++);

      expect(() => s.fillRange(0, 2, 0), throwsUnsupportedError);

      expect(calls, 0);
      expect(s.untrackedPreviousValue, same(previous));
    });

    test('fillRange with history that changes nothing on a default list makes '
        'no copy', () {
      final s = ListSignal([0, 0, 0, 4]);
      addTearDown(s.dispose);
      s[3] = 5;
      var calls = 0;
      s
        ..addListener(() => calls++)
        ..fillRange(0, 3, 0);

      expect(calls, 0);
      // The pending history of `s[3] = 5` is kept, so no copy replaced it.
      expect(s.untrackedPreviousValue, [0, 0, 0, 4]);
    });
  });

  group('adversarial round 4', () {
    test('fillRange without history keeps no per-slot buffer', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      backing.reads = 0;

      s.fillRange(0, 100, 7);

      // The first slot of the range, and that slot again after the write.
      expect(backing.reads, lessThanOrEqualTo(2));
      expect(s.untrackedValue, List.filled(100, 7));
      expect(runs, 2);
    });

    test('setRange without history reads only the range', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      backing.reads = 0;

      s.setRange(10, 13, const [1, 2, 3]);

      // The three slots before the write and the three slots after it.
      expect(backing.reads, lessThanOrEqualTo(6));
      expect(s.untrackedValue.sublist(10, 13), [1, 2, 3]);
      expect(runs, 2);
    });

    test('fillRange with history that changes nothing makes no copy', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([])..value = backing;
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      backing.reads = 0;

      s.fillRange(0, 3, 0);

      // The three slots of the range: no copy of the list.
      expect(backing.reads, lessThanOrEqualTo(3));
      expect(runs, 1);
    });
  });

  group('adversarial round 5', () {
    test('insert at the end does not call an overridden add', () {
      final s = _InsertingAddList([1, 2]);
      addTearDown(s.dispose);
      var calls = 0;
      s
        ..addListener(() => calls++)
        ..insert(2, 3);

      expect(s.addCalls, 0);
      expect(calls, 1);
      expect(s.untrackedValue, [1, 2, 3]);
      expect(s.untrackedPreviousValue, [1, 2]);
    });

    test('a rejected fill of an unmodifiable list reads a constant number '
        'of slots', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)
        ..value = UnmodifiableListView(backing);
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);
      backing.reads = 0;

      expect(() => s.fillRange(0, 100, 1), throwsUnsupportedError);

      // The first slot, and that slot again after the error.
      expect(backing.reads, lessThanOrEqualTo(2));
      expect(calls, 0);
    });

    test('a rejected fill with history checks one slot after the error', () {
      final backing = _CountingList(100);
      final s = ListSignal<int>([])..value = UnmodifiableListView(backing);
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);
      backing.reads = 0;

      expect(() => s.fillRange(0, 100, 1), throwsUnsupportedError);

      // The first slot, the history copy, and that slot again after the
      // error, but no comparison of the whole range.
      expect(backing.reads, lessThanOrEqualTo(102));
      expect(calls, 0);
    });

    test('a history read with nothing pending returns the stored value', () {
      final s = ListSignal([1, 2]);
      addTearDown(s.dispose);
      s.value = [3];

      expect(s.untrackedPreviousValue, [1, 2]);
      expect(s.untrackedPreviousValue, same(s.untrackedPreviousValue));
    });

    test('a rejected fill that a typed list would convert does not notify '
        'without history', () {
      final s = ListSignal<int>([], trackPreviousValue: false)
        ..value = Uint8List(100).asUnmodifiableView();
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);

      expect(() => s.fillRange(0, 100, 256), throwsUnsupportedError);

      expect(calls, 0);
      expect(s.untrackedValue, List.filled(100, 0));
    });

    test('a rejected fill of an unmodifiable typed list does not notify', () {
      final s = ListSignal<int>([], trackPreviousValue: false)
        ..value = Uint8List(100).asUnmodifiableView();
      addTearDown(s.dispose);
      var calls = 0;
      s.addListener(() => calls++);

      expect(() => s.fillRange(0, 100, 1), throwsUnsupportedError);

      expect(calls, 0);
      expect(s.untrackedValue, List.filled(100, 0));
    });

    test('insert at the end keeps exact history', () {
      final s = ListSignal([1, 2, 3]);
      addTearDown(s.dispose);

      s.insert(3, 4);

      expect(s.untrackedValue, [1, 2, 3, 4]);
      expect(s.untrackedPreviousValue, [1, 2, 3]);
      s.insert(0, 0);
      expect(s.untrackedPreviousValue, [1, 2, 3, 4]);
    });
  });

  group('adversarial round 3', () {
    test('replaceRange with a shorter list reads no slot before the write', () {
      final plain = _CountingList(100)..replaceRange(0, 100, const [7]);
      final backing = _CountingList(100);
      final s = ListSignal<int>([], trackPreviousValue: false)..value = backing;
      addTearDown(s.dispose);
      var runs = 0;
      final effect = Effect(() {
        s.value;
        runs++;
      });
      addTearDown(effect.dispose);
      backing.reads = 0;

      s.replaceRange(0, 100, const [7]);

      expect(backing.reads, plain.reads);
      expect(s.untrackedValue, [7]);
      expect(runs, 2);
    });

    for (final history in [false, true]) {
      test('addAll into an empty map does not list the input keys, history '
          '$history', () {
        final s = MapSignal<int, int>({}, trackPreviousValue: history);
        addTearDown(s.dispose);
        var runs = 0;
        final effect = Effect(() {
          s.value;
          runs++;
        });
        addTearDown(effect.dispose);
        final input = _KeyCountingMap();

        s.addAll(input);

        expect(input.keyReads, 0);
        expect(s.untrackedValue, hasLength(100));
        expect(runs, 2);
        if (history) expect(s.untrackedPreviousValue, isEmpty);
      });
    }
  });
}

/// A map that counts how often its keys are listed.
class _KeyCountingMap extends DelegatingMap<int, int> {
  _KeyCountingMap() : super({for (var i = 0; i < 100; i++) i: i});
  int keyReads = 0;

  @override
  Iterable<int> get keys {
    keyReads++;
    return super.keys;
  }
}

class _HashKey {
  _HashKey(this.hash);

  final int Function() hash;

  @override
  // ignore: hash_and_equals, avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => hash();
}

class _CountedMapValue {
  _CountedMapValue(this.key, this.onHash, {this.onEquals});

  final int key;
  final void Function() onHash;
  final void Function()? onEquals;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode {
    onHash();
    return key;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    onEquals?.call();
    return other is _CountedMapValue && key == other.key;
  }
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

/// A map that yields the key 'b' and then throws, both from [keys] and
/// from [forEach].
class _ThrowAfterFirstMap extends MapBase<String, int> {
  @override
  int? operator [](Object? key) => key == 'b' ? 2 : null;

  @override
  void operator []=(String key, int value) => throw UnimplementedError();

  @override
  void clear() => throw UnimplementedError();

  @override
  Iterable<String> get keys => _throwAfter(['b']);

  @override
  int get length => 2;

  @override
  int? remove(Object? key) => throw UnimplementedError();
}

/// A list of entries whose iterator yields `b: 2` and then throws.
class _ThrowAfterFirstList extends ListBase<MapEntry<String, int>> {
  @override
  int get length => 2;

  @override
  set length(int newLength) => throw UnimplementedError();

  @override
  MapEntry<String, int> operator [](int index) => const MapEntry('b', 2);

  @override
  void operator []=(int index, MapEntry<String, int> value) =>
      throw UnimplementedError();

  @override
  Iterator<MapEntry<String, int>> get iterator =>
      _throwAfter([const MapEntry('b', 2)]).iterator;
}

class _CountingObserver extends SolidartObserver {
  int updates = 0;

  @override
  void didCreateSignal(SignalBase<Object?> signal) {}

  @override
  void didUpdateSignal(SignalBase<Object?> signal) => updates++;

  @override
  void didDisposeSignal(SignalBase<Object?> signal) {}
}

/// A key with value equality whose value can change after a write.
class _MutableKey {
  _MutableKey(this.id);

  int id;

  // The test needs a key whose equality changes.
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is _MutableKey && other.id == id;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => id.hashCode;
}

/// A list whose `[]` counts reads. `last`, `removeLast`, `removeAt`,
/// `insert` and `iterator` do not use `[]`, like a sequential backing.
class _SequentialList extends ListBase<int> {
  _SequentialList(List<int> elements) : _elements = List.of(elements);

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

  @override
  int get last => _elements.last;

  @override
  int removeLast() => _elements.removeLast();

  @override
  int removeAt(int index) => _elements.removeAt(index);

  @override
  void insert(int index, int element) => _elements.insert(index, element);

  @override
  Iterator<int> get iterator => _elements.iterator;
}

/// A list signal whose `add` is written with `insert` at the end.
class _InsertingAddList extends ListSignal<int> {
  _InsertingAddList(super.initialValue);

  int addCalls = 0;

  @override
  void add(int element) {
    addCalls++;
    insert(length, element);
  }
}
