import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

class _ReadCountingList extends DelegatingList<Object?> {
  _ReadCountingList(super.base);

  int indexedReads = 0;

  @override
  Object? operator [](int index) {
    indexedReads++;
    return super[index];
  }
}

class _LookupCountingMap extends MapView<String, int?> {
  _LookupCountingMap(super.map);

  int lookups = 0;

  @override
  int? operator [](Object? key) {
    lookups++;
    return super[key];
  }
}

class _ReactiveElement {
  _ReactiveElement(this.matches);

  final Signal<bool> matches;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => identical(this, other) || matches.value;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}

void main() {
  test('map equality accepts the same entries in either order', () {
    final original = {7: 6, 14: 3};
    final map = MapSignal(original, equals: true);
    addTearDown(map.dispose);

    map.value = {7: 6, 14: 3};
    expect(map.untrackedValue, same(original));

    map.value = {14: 3, 7: 6};
    expect(map.untrackedValue, same(original));

    map.value = {7: 6, 14: 0};
    expect(map.untrackedValue, {7: 6, 14: 0});
    expect(map.untrackedPreviousValue, same(original));
  });

  test('ListSignal.contains uses the backing list search', () {
    final backing = _ReadCountingList([1, null]);
    final list = ListSignal<Object?>([])..value = backing;
    addTearDown(list.dispose);

    expect(list.contains(null), isTrue);
    expect(list.contains('missing'), isFalse);
    expect(backing.indexedReads, 0);
  });

  test('ListSignal.indexOf uses the backing list search', () {
    final backing = _ReadCountingList([null, 1, null]);
    final list = ListSignal<Object?>([])..value = backing;
    addTearDown(list.dispose);

    expect(list.indexOf(null, -1), 0);
    expect(list.indexOf(null, 1), 2);
    expect(list.indexOf(null, 3), -1);
    expect(backing.indexedReads, 0);
  });

  test('ListSignal.indexOf accepts a wider query than its typed backing', () {
    final list = ListSignal<num>([])..value = Uint8List.fromList([1, 2, 1]);
    addTearDown(list.dispose);

    expect(list.indexOf(1.0), 0);
    expect(list.indexOf(1.0, 1), 2);
    expect(list.indexOf('missing'), -1);
  });

  for (final (name, search) in <(String, bool Function(ListSignal<Object>))>[
    ('contains', (list) => list.contains('needle')),
    ('indexOf', (list) => list.indexOf('needle') == 0),
  ]) {
    test('ListSignal.$name tracks the list and reads in element equality', () {
      final matches = Signal(false);
      final list = ListSignal<Object>([_ReactiveElement(matches)]);
      final results = <bool>[];
      final effect = Effect(() => results.add(search(list)));
      addTearDown(matches.dispose);
      addTearDown(list.dispose);
      addTearDown(effect.dispose);

      matches.value = true;
      list.clear();

      expect(results, [false, true, false]);
    });
  }

  test(
    'MapSignal.forEach uses backing traversal and tracks callback reads',
    () {
      final backing = _LookupCountingMap({'b': null, 'a': 2});
      final map = MapSignal(backing);
      final offset = Signal(0);
      final results = <List<(String, int)>>[];
      final effect = Effect(() {
        final entries = <(String, int)>[];
        map.forEach(
          (key, value) => entries.add((key, (value ?? 0) + offset.value)),
        );
        results.add(entries);
      });
      addTearDown(offset.dispose);
      addTearDown(map.dispose);
      addTearDown(effect.dispose);

      offset.value = 1;
      map.value = {'c': 3};

      expect(results, [
        [('b', 0), ('a', 2)],
        [('b', 1), ('a', 3)],
        [('c', 4)],
      ]);
      expect(backing.lookups, 0);
    },
  );
}
