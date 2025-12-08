import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  test('Signal respects custom equals comparator', () {
    var runs = 0;
    final s = Signal(
      0,
      equals: (a, b) => a == b,
    );
    Effect(() {
      s.value;
      runs++;
    });

    expect(runs, 1, reason: 'effect runs once on creation');

    s.value = 0; // same value, should be ignored
    expect(runs, 1);

    s.value = 1; // different value, should rerun
    expect(runs, 2);

    s.value = 1; // same again, ignored
    expect(runs, 2);
  });

  test('Computed respects custom equals comparator', () {
    var runs = 0;
    final source = Signal(0);
    final comp = Computed(
      () => source.value,
      equals: (a, b) {
        final prevParity = (a ?? 0).isEven;
        final nextParity = (b ?? 0).isEven;
        return prevParity == nextParity;
      },
    );

    Effect(() {
      comp.value;
      runs++;
    });

    expect(runs, 1);

    source.value = 2; // parity unchanged (even), skip recompute
    expect(runs, 1);

    source.value = 3; // parity changed (odd), recompute
    expect(runs, 2);
  });
}
