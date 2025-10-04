/// Abstract interface for an effect.
abstract interface class Effect {
  /// Indicate if the reaction is dispose
  bool get disposed;

  /// Disposes the reaction
  void dispose();

  /// The name of the effect, useful for logging purposes.
  String get name;

  /// Whether to automatically dispose the effect (defaults to true).
  bool get autoDispose;
}
