import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  test('untracked prevents dependency tracking', () {
    final count = Signal(0);
    final effectCount = Signal(0);
    var runs = 0;

    Effect(() {
      count.value;
      runs++;
      effectCount.value = untracked(() => effectCount.value + 1);
    });

    expect(runs, 1);
    expect(effectCount.value, 1);

    count.value = 1;

    expect(runs, 2);
    expect(effectCount.value, 2);

    effectCount.value = 3;

    expect(runs, 2);
  });
}
