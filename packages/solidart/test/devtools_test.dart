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
  });
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
