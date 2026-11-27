@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:solidart/solidart.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' show VmService;

import 'devtools_test_harness.dart';

Future<Map<String, dynamic>> _nextUpdate(VmService service, String name) async {
  final event = await service.onExtensionEvent.firstWhere(
    (event) =>
        event.extensionKind == 'ext.solidart.signal.updated' &&
        event.extensionData?.data['name'] == name,
  );
  return event.extensionData!.data;
}

void main() {
  test('an idle Extension stream leaves signal work to observers', () async {
    // The stream is shared across the VM, including other test isolates.
    const fixture = 'test/fixtures/devtools_without_listener.dart';
    final script = File(fixture).existsSync()
        ? fixture
        : 'packages/solidart/$fixture';
    final dart = Platform.environment['FLUTTER_TEST'] == 'true'
        ? 'dart'
        : Platform.resolvedExecutable;
    final result = await Process.run(dart, [script]);
    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(jsonDecode(result.stdout as String), {
      'hasListener': false,
      'valueReads': 0,
      'historyReads': 0,
      'updateHistoryHashes': 0,
      'serializations': 0,
      'observerEvents': ['created', 'updated', 'disposed'],
    });
  });

  for (final (keyText, firstKey, secondKey) in [
    ('[1]', [1], [1]),
    ('"same"', _SameTextKey(), _SameTextKey()),
  ]) {
    testWithDevTools('a map event keeps both entries with key text $keyText', (
      service,
    ) async {
      const name = 'map with colliding key text';
      final updated = _nextUpdate(service, name);
      final map = MapSignal<Object, int>({
        firstKey: 10,
        secondKey: 20,
      }, name: name);
      addTearDown(map.dispose);

      map['added'] = 30;

      final data = await updated;
      expect(data['hasPreviousValue'], isTrue);
      expect(
        jsonDecode(data['previousValue'] as String),
        '{$keyText: 10, $keyText: 20}',
      );
      expect(
        jsonDecode(data['value'] as String),
        '{$keyText: 10, $keyText: 20, "added": 30}',
      );
    });
  }

  testWithDevTools('a map event keeps distinct keys with equal strings', (
    service,
  ) async {
    const name = 'map with equal string keys';
    final updated = _nextUpdate(service, name);
    final map = MapSignal(_identityMap(10, 20), name: name);
    addTearDown(map.dispose);

    map.value = _identityMap(10, 20)..['added'] = 30;

    final data = await updated;
    expect(data['hasPreviousValue'], isTrue);
    expect(jsonDecode(data['previousValue'] as String), '{"a":10,"a":20}');
    expect(
      jsonDecode(data['value'] as String),
      '{"a":10,"a":20,"added":30}',
    );
  });

  testWithDevTools('nested map events keep distinct keys with equal strings', (
    service,
  ) async {
    const name = 'nested map with equal string keys';
    const text = r'{"a":"\"\\{}", "a":20}';
    final updated = _nextUpdate(service, name);
    final sent = <int>[];
    final signal = Signal([
      {
        'nested': _identityMap(10, 20),
        'probe': _SentProbe(1, sent),
        'text': text,
      },
    ], name: name);
    addTearDown(signal.dispose);

    sent.clear();
    signal.value = [
      {
        'nested': _identityMap(30, 40),
        'probe': _SentProbe(2, sent),
        'text': text,
      },
    ];

    final data = await updated;
    expect(jsonDecode(data['previousValue'] as String), [
      {'nested': '{"a":10,"a":20}', 'probe': 1, 'text': text},
    ]);
    expect(jsonDecode(data['value'] as String), [
      {'nested': '{"a":30,"a":40}', 'probe': 2, 'text': text},
    ]);
    expect(sent, [2, 1]);
  });

  testWithDevTools('map events keep unique string keys in a JSON object', (
    service,
  ) async {
    const name = 'map with string keys';
    final updated = _nextUpdate(service, name);
    final map = MapSignal<String, Object>({'count': 1}, name: name);
    addTearDown(map.dispose);

    final date = DateTime.utc(2026);
    map['date'] = date;

    final data = await updated;
    expect(jsonDecode(data['previousValue'] as String), {'count': 1});
    expect(
      jsonDecode(data['value'] as String),
      {'count': 1, 'date': date.toString()},
    );
  });

  group('DevTools inspection does not change signal behavior', () {
    testWithDevTools(
      'a dependency-free autoDispose Computed is not disposed at creation',
      (_) {
        final constant = Computed(() => 1, autoDispose: true);
        expect(constant.disposed, isFalse);
        expect(constant.value, 1);
        // A read by the user still runs the auto-dispose check.
        expect(constant.disposed, isTrue);
      },
    );

    testWithDevTools('a lazy Computed does not run its selector at creation', (
      _,
    ) {
      var runs = 0;
      final computed = Computed(() => ++runs);
      expect(runs, 0);
      expect(computed.value, 1);
      computed.dispose();
    });

    testWithDevTools('the first value of a lazy Computed is sent to DevTools', (
      _,
    ) {
      final sent = <int>[];
      final computed = Computed(() => _SentProbe(42, sent));
      expect(sent, isEmpty);
      expect(computed.value.id, 42);
      expect(sent, [42]);
    });

    testWithDevTools(
      'an autoDispose Computed is disposed with its only dependency',
      (_) {
        final source = Signal(1);
        final doubled = Computed(() => source.value * 2, autoDispose: true);
        expect(doubled.value, 2);
        source.value = 2;
        expect(doubled.value, 4);

        source.dispose();
        expect(doubled.disposed, isTrue);
      },
    );

    testWithDevTools('a lazy Resource does not start its fetcher at creation', (
      _,
    ) async {
      var fetches = 0;
      final resource = Resource<int>(() async => ++fetches);
      expect(fetches, 0);
      await resource.untilReady();
      expect(fetches, 1);
      resource.dispose();
    });

    testWithDevTools('an effect does not depend on a signal it creates', (_) {
      Signal<int>? created;
      var runs = 0;
      final effect = Effect(() {
        runs++;
        created ??= Signal(0);
      });

      created!.value = 1;
      expect(runs, 1);
      effect.dispose();
    });

    testWithDevTools('a Computed does not depend on signals read by toJson', (
      _,
    ) {
      final source = Signal(0);
      final other = Signal(0);
      var runs = 0;
      final computed = Computed(() {
        runs++;
        return _JsonProbe(source.value, other);
      });
      expect(computed.value.source, 0);
      source.value = 1;
      expect(computed.value.source, 1);

      final runsBefore = runs;
      other.value = 1;
      expect(computed.value.source, 1);
      expect(runs, runsBefore);
    });

    testWithDevTools(
      'toJson reading an autoDispose Computed does not dispose it',
      (_) {
        final other = Computed(() => 1, autoDispose: true);
        final holder = Computed(() => _ReadingJsonProbe(other));
        expect(holder.value.other, same(other));
        expect(other.disposed, isFalse);
        // A read by the user still runs the auto-dispose check.
        expect(other.value, 1);
        expect(other.disposed, isTrue);
      },
    );

    testWithDevTools(
      'toString reading an autoDispose Computed does not dispose it',
      (_) {
        final other = Computed(() => 1, autoDispose: true);
        final holder = Computed(() => _ReadingStringProbe(other));
        expect(holder.value.other, same(other));
        expect(other.disposed, isFalse);
        expect(other.value, 1);
        expect(other.disposed, isTrue);
      },
    );

    testWithDevTools(
      'a Computed read by toJson keeps track of inputs for disposal',
      (_) {
        final source = Signal(42, autoDispose: true);
        final inner = Computed(() => source.value, autoDispose: true);
        final outer = Computed(() => inner.value);
        final holder = Signal(_ReadingJsonProbe(outer));
        addTearDown(holder.dispose);

        expect(outer.value, 42);
        outer.dispose();

        expect(inner.disposed, isTrue);
        expect(source.disposed, isTrue);
      },
    );

    testWithDevTools(
      'reading map history for an event does not dispose a Computed',
      (_) {
        final other = Computed(() => 1, autoDispose: true);
        var readComputed = false;
        var reads = 0;
        final key = _ReadingMapKey(() {
          if (readComputed) {
            reads++;
            other.value;
          }
        });
        final map = MapSignal<Object, int>({key: 1});
        readComputed = true;

        map['new'] = 2;

        expect(reads, greaterThan(0));
        expect(other.disposed, isFalse);
      },
    );

    testWithDevTools(
      'reading the event value type does not dispose a Computed',
      (_) {
        final other = Computed(() => 1, autoDispose: true);
        final probe = _ReadingTypeProbe(other);
        final holder = Signal(probe);
        addTearDown(holder.dispose);

        expect(probe.reads, greaterThan(0));
        expect(other.disposed, isFalse);
      },
    );

    testWithDevTools(
      'checking DevTools eligibility does not dispose a Computed',
      (_) {
        var evaluations = 0;
        final policy = Computed(() {
          evaluations++;
          return true;
        }, autoDispose: true);
        final tracked = _PolicyComputed()..policy = policy;
        addTearDown(tracked.dispose);
        addTearDown(policy.dispose);

        expect(tracked.value, 3);
        expect(evaluations, 1);
        expect(policy.disposed, isFalse);
        expect(policy.value, isTrue);
        expect(policy.disposed, isTrue);
      },
    );

    testWithDevTools(
      'checking DevTools eligibility does not subscribe its reader',
      (_) {
        final input = Signal(true);
        final policy = Computed(() => input.value);
        final tracked = _PolicyComputed()..policy = policy;
        final seen = <int>[];
        final effect = Effect(() => seen.add(tracked.value));
        addTearDown(() {
          effect.dispose();
          tracked.dispose();
          policy.dispose();
          input.dispose();
        });

        input.value = false;

        expect(seen, [3]);
      },
    );

    testWithDevTools(
      'a throwing serialization does not keep auto-disposal off',
      (_) {
        final other = Computed(() => 1, autoDispose: true);
        final holder = Computed(() => _ThrowingProbe(other));
        expect(() => holder.value, throwsStateError);
        expect(other.disposed, isFalse);

        final later = Computed(() => 2, autoDispose: true);
        expect(later.value, 2);
        expect(later.disposed, isTrue);
      },
    );
  });
}

Map<String, int> _identityMap(int first, int second) =>
    Map<String, int>.identity()
      ..[String.fromCharCodes([97])] = first
      ..[String.fromCharCodes([97])] = second;

class _SameTextKey {
  String toJson() => 'same';
}

class _PolicyComputed extends Computed<int> {
  _PolicyComputed() : super(() => 3);

  Computed<bool>? policy;

  @override
  bool get trackInDevTools => policy?.value ?? false;
}

class _JsonProbe {
  _JsonProbe(this.source, this.other);

  final int source;
  final Signal<int> other;

  Object? toJson() => other.value;
}

/// Records each serialization for a DevTools event.
class _SentProbe {
  _SentProbe(this.id, this.sent);

  final int id;
  final List<int> sent;

  Object? toJson() {
    sent.add(id);
    return id;
  }
}

/// Reads an autoDispose Computed while DevTools serializes it.
class _ReadingJsonProbe {
  _ReadingJsonProbe(this.other);

  final Computed<int> other;

  Object? toJson() => other.value;
}

/// Has no toJson, so DevTools falls back to toString.
class _ReadingStringProbe {
  _ReadingStringProbe(this.other);

  final Computed<int> other;

  @override
  String toString() => 'value: ${other.value}';
}

@immutable
class _ReadingMapKey {
  const _ReadingMapKey(this.onHash);

  final void Function() onHash;

  @override
  int get hashCode {
    onHash();
    return identityHashCode(this);
  }

  @override
  bool operator ==(Object other) => identical(this, other);
}

class _ReadingTypeProbe {
  _ReadingTypeProbe(this.other);

  final Computed<int> other;
  int reads = 0;

  Object? toJson() => 0;

  @override
  Type get runtimeType {
    reads++;
    other.value;
    return _ReadingTypeProbe;
  }
}

/// Reads an autoDispose Computed, then fails in both toJson and toString.
class _ThrowingProbe {
  _ThrowingProbe(this.other);

  final Computed<int> other;

  Object? toJson() {
    other.value;
    throw StateError('toJson');
  }

  @override
  String toString() {
    other.value;
    throw StateError('toString');
  }
}
