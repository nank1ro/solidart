// ignore_for_file: avoid_print

import 'dart:async';

import 'package:solidart/solidart.dart';

Future<void> main() async {
  final count = Signal(0);
  final doubleCount = Computed(() => count() * 2);

  Effect((dispose) {
    print('The counter is now: ${count()}');
    print('The double counter is now: ${doubleCount()}');
  });

  count
    ..set(1)
    ..set(2);
}
