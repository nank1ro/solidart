import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

const _skip = Object();

void expectPreviousValues<T>(
  ReadonlySignal<T> signal, {
  Object? previous = _skip,
  Object? untracked = _skip,
}) {
  if (previous != _skip && untracked != _skip) {
    final values = (
      previous: signal.previousValue,
      untracked: signal.untrackedPreviousValue,
    );

    expect(values.previous, previous);
    expect(values.untracked, untracked);
    return;
  }

  if (previous != _skip) {
    expect(signal.previousValue, previous);
  }

  if (untracked != _skip) {
    expect(signal.untrackedPreviousValue, untracked);
  }
}

void main() {
  group('Signal previous value', () {
    test('tracks previousValue and untrackedPreviousValue', () {
      final signal = Signal(0);

      expectPreviousValues(signal, previous: null, untracked: null);

      signal.value = 1;

      expectPreviousValues(signal, previous: 0, untracked: 0);

      signal.value = 2;

      expectPreviousValues(signal, previous: 1, untracked: 1);
    });

    test('updates previous only after read', () {
      final signal = Signal(0);

      expectPreviousValues(signal..value = 1, untracked: null);

      final _ = signal.value;

      expectPreviousValues(signal, untracked: 0);
    });

    test('respects trackPreviousValue false', () {
      final signal = Signal(0, trackPreviousValue: false);

      expectPreviousValues(
        signal
          ..value = 1
          ..value,
        previous: null,
        untracked: null,
      );
    });
  });

  group('Computed previous value', () {
    test('tracks previousValue and untrackedPreviousValue', () {
      final source = Signal(1);
      final computed = Computed(() => source.value * 2);

      expectPreviousValues(computed, previous: null, untracked: null);
      expect(computed.value, 2);

      source.value = 2;

      expectPreviousValues(computed, previous: 2, untracked: 2);
      expect(computed.value, 4);
    });

    test('updates previous only after read', () {
      final source = Signal(1);
      final computed = Computed(() => source.value * 2);

      {
        final _ = computed.value;
      }

      source.value = 2;

      expectPreviousValues(computed, untracked: null);

      {
        final _ = computed.value;
      }

      expectPreviousValues(computed, untracked: 2);
    });

    test('respects trackPreviousValue false', () {
      final source = Signal(1);
      final computed = Computed(
        () => source.value * 2,
        trackPreviousValue: false,
      );

      {
        final _ = computed.value;
      }
      source.value = 2;
      {
        final _ = computed.value;
      }

      expectPreviousValues(computed, previous: null, untracked: null);
    });

    test('untrackedValue computes when not initialized', () {
      final source = Signal(2);
      final computed = Computed(() => source.value * 2);

      final value = computed.untrackedValue;

      expect(value, 4);
    });

    test('untrackedValue returns cached value when available', () {
      final source = Signal(3);
      final computed = Computed(() => source.value * 2);

      expect(computed.value, 6);

      final value = computed.untrackedValue;

      expect(value, 6);
    });
  });

  group('LazySignal previous value', () {
    test('throws when read before initialization', () {
      final lazy = LazySignal<int>();
      expect(() => lazy.value, throwsStateError);
    });

    test('tracks previous only after initialized and read', () {
      final lazy = LazySignal<int>();

      expectPreviousValues(lazy..value = 1, previous: null, untracked: null);
      expect(lazy.isInitialized, isTrue);

      lazy.value = 2;

      expectPreviousValues(lazy, untracked: null);

      final _ = lazy.value;

      expectPreviousValues(lazy, untracked: 1);
    });
  });
}
