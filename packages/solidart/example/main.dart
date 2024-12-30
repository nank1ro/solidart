// ignore_for_file: avoid_print

import 'package:solidart/solidart.dart';

// Future<void> main() async {
//   final count = Signal(0);
//   final doubleCount = Computed(() => count() * 2);
//
//   Effect((dispose) {
//     print('The counter is now: ${count()}');
//     print('The double counter is now: ${doubleCount()}');
//   });
//
//   count
//     ..set(1)
//     ..set(2);
// }
//
void main() {
  final count = Signal(0);
  final doubled = Computed(() => count() * 2);

  final disposeEffectA = Effect((_) {
    print('scope count: ${count()}');
  });

  final disposeEffectB = Effect((_) {
    print('scope doubled: ${doubled()}');
  });

  Effect((_) {
    print('count: ${count()} double: ${doubled()}');
  });

  count.set(1);

  disposeEffectA();
  disposeEffectB();

  count.set(2);
}
