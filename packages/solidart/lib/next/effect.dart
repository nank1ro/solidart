import 'package:alien_signals/alien_signals.dart' as alien;
import 'package:alien_signals/preset_developer.dart' as alien;
import 'package:solidart/next/_internal/disposable.dart';
import 'package:solidart/next/_internal/name_for.dart';
import 'package:solidart/next/config.dart';

part '_internal/solidart_effect.dart';

/// Abstract interface for an effect.
abstract interface class Effect {
  /// Whether to automatically dispose the effect (defaults to true).
  bool get autoDispose;

  /// Indicate if the reaction is dispose
  bool get disposed;

  /// The name of the effect, useful for logging purposes.
  String get name;

  /// Run the effect callback
  void run();

  /// Disposes the reaction
  void dispose();
}
