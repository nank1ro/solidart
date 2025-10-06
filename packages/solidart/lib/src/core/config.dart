import '../devtools/observer.dart';

base class SolidartConfig {
  const SolidartConfig._();

  static bool autoDispose = true;
  static bool detachEffects = false;
  static bool enableDevTools = true;
  static final observers = <SolidartObserver>[];
}
