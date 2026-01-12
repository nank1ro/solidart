import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  test('Signal call() returns value and tracks dependencies', () {
    final counter = Signal(0);
    var runs = 0;

    Effect(() {
      counter();
      runs++;
    });

    expect(runs, 1);

    counter.value = 1;
    expect(runs, 2);
  });

  test('ReadonlySignal call() works on typed reference', () {
    final counter = Signal(0);
    final readonly = counter.toReadonly();

    expect(readonly(), 0);

    counter.value = 2;
    expect(readonly(), 2);
  });

  test('Computed call() returns value and tracks dependencies', () {
    final source = Signal(1);
    final doubled = Computed(() => source.value * 2);
    var runs = 0;

    Effect(() {
      doubled();
      runs++;
    });

    expect(runs, 1);

    source.value = 3;
    expect(runs, 2);
    expect(doubled(), 6);
  });
}
