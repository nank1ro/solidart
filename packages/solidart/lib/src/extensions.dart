import 'package:solidart/src/core/signal.dart';

/// Adds the [toggle] method to boolean signals
extension ToggleBoolSignal on Signal<bool> {
  /// Toggles the signal boolean value.
  void toggle() => value = !value;
}
