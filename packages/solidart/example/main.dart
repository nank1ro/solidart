// ignore_for_file: avoid_print

import 'package:solidart/solidart.dart';

void main() {
  final count = Signal(0);
  final doubleCount = Computed(() => count.value * 2);

  Effect(() {
    print('The counter is now: ${count.value}');
    print('The double counter is now: ${doubleCount.value}');
  });

  count
    ..value = 1
    ..value = 2;
}
