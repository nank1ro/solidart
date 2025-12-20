import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  group('Signal previous value', () {
    test('tracks previousValue and untrackedPreviousValue', () {
      final signal = Signal(0);

      expect(signal.previousValue, isNull);
      expect(signal.untrackedPreviousValue, isNull);

      signal.value = 1;

      expect(signal.previousValue, 0);
      expect(signal.untrackedPreviousValue, 0);

      signal.value = 2;

      expect(signal.previousValue, 1);
      expect(signal.untrackedPreviousValue, 1);
    });

    test('updates previous only after read', () {
      final signal = Signal(0);

      signal.value = 1;

      expect(signal.untrackedPreviousValue, isNull);

      signal.value;

      expect(signal.untrackedPreviousValue, 0);
    });

    test('respects trackPreviousValue false', () {
      final signal = Signal(0, trackPreviousValue: false);

      signal.value = 1;
      signal.value;

      expect(signal.previousValue, isNull);
      expect(signal.untrackedPreviousValue, isNull);
    });
  });

  group('Computed previous value', () {
    test('tracks previousValue and untrackedPreviousValue', () {
      final source = Signal(1);
      final computed = Computed(() => source.value * 2);

      expect(computed.previousValue, isNull);
      expect(computed.value, 2);

      source.value = 2;

      expect(computed.previousValue, 2);
      expect(computed.untrackedPreviousValue, 2);
      expect(computed.value, 4);
    });

    test('updates previous only after read', () {
      final source = Signal(1);
      final computed = Computed(() => source.value * 2);

      computed.value;

      source.value = 2;

      expect(computed.untrackedPreviousValue, isNull);

      computed.value;

      expect(computed.untrackedPreviousValue, 2);
    });

    test('respects trackPreviousValue false', () {
      final source = Signal(1);
      final computed = Computed(
        () => source.value * 2,
        trackPreviousValue: false,
      );

      computed.value;
      source.value = 2;
      computed.value;

      expect(computed.previousValue, isNull);
      expect(computed.untrackedPreviousValue, isNull);
    });
  });
}
