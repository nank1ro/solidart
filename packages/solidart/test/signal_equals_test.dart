import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  test('a signal with equals: true compares values with ==', () {
    // Equal values that are not identical objects.
    final signal = Signal(BigInt.from(1 << 40), equals: true);
    addTearDown(signal.dispose);
    var runs = 0;
    final effect = Effect(() {
      signal.value;
      runs++;
    });
    addTearDown(effect.dispose);

    signal.value = BigInt.from(1 << 40);
    expect(runs, 1);

    signal.value = BigInt.from(2);
    expect(runs, 2);
  });

  test('a comparator can force an update during a signal read', () {
    late final Signal<int> signal;
    var comparisons = 0;
    signal = Signal(
      0,
      equals: false,
      comparator: (old, next) {
        if (++comparisons == 2) signal.notifyListeners();
        return old == next;
      },
    );
    addTearDown(signal.dispose);

    signal.value = 1;

    expect(signal.value, 1);
    expect(signal.shouldUpdate(), isTrue);
    expect(signal.shouldUpdate(), isFalse);
  });
}
