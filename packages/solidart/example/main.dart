// ignore_for_file: avoid_print

import 'package:solidart/solidart.dart';

void main() {
  final count = Signal(0);
  final doubleCount = Computed(() => count() * 2);

  Effect(() {
    print('The counter is now: ${count()}');
    print('The double counter is now: ${doubleCount()}');
  });

  count
    ..set(1)
    ..set(2);
}
