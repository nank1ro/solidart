import 'package:meta/meta.dart';
import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('DevTools inspection does not change signal behavior', () {
    setUp(() {
      final devToolsEnabled = SolidartConfig.devToolsEnabled;
      addTearDown(() => SolidartConfig.devToolsEnabled = devToolsEnabled);
      SolidartConfig.devToolsEnabled = true;
    });

    test(
      'a dependency-free autoDispose Computed is not disposed at creation',
      () {
        final constant = Computed(() => 1, autoDispose: true);
        expect(constant.disposed, isFalse);
        expect(constant.value, 1);
        // A read by the user still runs the auto-dispose check.
        expect(constant.disposed, isTrue);
      },
    );

    test('a lazy Computed does not run its selector at creation', () {
      var runs = 0;
      final computed = Computed(() => ++runs);
      expect(runs, 0);
      expect(computed.value, 1);
      computed.dispose();
    });

    test('the first value of a lazy Computed is sent to DevTools', () {
      final sent = <int>[];
      final computed = Computed(() => _SentProbe(42, sent));
      expect(sent, isEmpty);
      expect(computed.value.id, 42);
      expect(sent, [42]);
    });

    test('an autoDispose Computed is disposed with its only dependency', () {
      final source = Signal(1);
      final doubled = Computed(() => source.value * 2, autoDispose: true);
      expect(doubled.value, 2);
      source.value = 2;
      expect(doubled.value, 4);

      source.dispose();
      expect(doubled.disposed, isTrue);
    });

    test('a lazy Resource does not start its fetcher at creation', () async {
      var fetches = 0;
      final resource = Resource<int>(() async => ++fetches);
      expect(fetches, 0);
      await resource.untilReady();
      expect(fetches, 1);
      resource.dispose();
    });

    test('an effect does not depend on a signal it creates', () {
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

    test('a Computed does not depend on signals read by toJson', () {
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

    test('toJson reading an autoDispose Computed does not dispose it', () {
      final other = Computed(() => 1, autoDispose: true);
      final holder = Computed(() => _ReadingJsonProbe(other));
      expect(holder.value.other, same(other));
      expect(other.disposed, isFalse);
      // A read by the user still runs the auto-dispose check.
      expect(other.value, 1);
      expect(other.disposed, isTrue);
    });

    test('toString reading an autoDispose Computed does not dispose it', () {
      final other = Computed(() => 1, autoDispose: true);
      final holder = Computed(() => _ReadingStringProbe(other));
      expect(holder.value.other, same(other));
      expect(other.disposed, isFalse);
      expect(other.value, 1);
      expect(other.disposed, isTrue);
    });

    test('a Computed read by toJson keeps track of inputs for disposal', () {
      final source = Signal(42, autoDispose: true);
      final inner = Computed(() => source.value, autoDispose: true);
      final outer = Computed(() => inner.value);
      final holder = Signal(_ReadingJsonProbe(outer));
      addTearDown(holder.dispose);

      expect(outer.value, 42);
      outer.dispose();

      expect(inner.disposed, isTrue);
      expect(source.disposed, isTrue);
    });

    test('reading map history for an event does not dispose a Computed', () {
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
    });

    test('reading the event value type does not dispose a Computed', () {
      final other = Computed(() => 1, autoDispose: true);
      final probe = _ReadingTypeProbe(other);
      final holder = Signal(probe);
      addTearDown(holder.dispose);

      expect(probe.reads, greaterThan(0));
      expect(other.disposed, isFalse);
    });

    test('checking DevTools eligibility does not dispose a Computed', () {
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
    });

    test('checking DevTools eligibility does not subscribe its reader', () {
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
    });

    test('a throwing serialization does not keep auto-disposal off', () {
      final other = Computed(() => 1, autoDispose: true);
      final holder = Computed(() => _ThrowingProbe(other));
      expect(() => holder.value, throwsStateError);
      expect(other.disposed, isFalse);

      final later = Computed(() => 2, autoDispose: true);
      expect(later.value, 2);
      expect(later.disposed, isTrue);
    });
  });
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
