import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  test('batch groups updates and flushes once', () {
    final x = Signal(10);
    final y = Signal(20);
    final total = Signal(30);

    final calls = <({int x, int y, int total})>[];

    Effect(() {
      calls.add((x: x.value, y: y.value, total: total.value));
    });

    expect(calls, [
      (x: 10, y: 20, total: 30),
    ]);

    batch(() {
      x.value++;
      y.value++;
      total.value = x.value + y.value;
    });

    expect(calls, [
      (x: 10, y: 20, total: 30),
      (x: 11, y: 21, total: 32),
    ]);
  });
}
