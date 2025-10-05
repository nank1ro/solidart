import 'core/computed.dart';
import 'core/effect.dart';
import 'core/signal.dart';

main() {
  final s = SolidartSignal(1);
  final s2 = SolidartSignal(1);
  final c = SolidartComputed(() => s.value * 2);
  final e = SolidartEffect(() {
    c.value;
    s2.value;
  });

  e.dispose();
  print(s.disposed);
  print(s2.disposed);
  print(c.disposed);
}
