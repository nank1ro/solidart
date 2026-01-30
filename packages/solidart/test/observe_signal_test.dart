import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('ObserveSignal', () {
    test('skips initial run and reports changes', () {
      final signal = Signal(0);
      final calls = <List<int?>>[];

      final dispose = signal.observe((previous, value) {
        calls.add([previous, value]);
      });

      expect(calls, isEmpty);

      signal.value = 1;
      expect(
        calls,
        equals(<List<int?>>[
          <int?>[0, 1],
        ]),
      );

      dispose();
      signal.value = 2;
      expect(
        calls,
        equals(<List<int?>>[
          <int?>[0, 1],
        ]),
      );

      signal.dispose();
    });

    test('fires immediately when requested', () {
      final signal = Signal(5);
      final calls = <List<int?>>[];

      final dispose = signal.observe(
        (previous, value) {
          calls.add([previous, value]);
        },
        fireImmediately: true,
      );

      expect(
        calls,
        equals(<List<int?>>[
          <int?>[null, 5],
        ]),
      );

      dispose();
      signal.dispose();
    });
  });
}
