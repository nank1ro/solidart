part of '../widgets/provider_scope.dart';

/// -------------------------------
/// Provider extensions
/// -------------------------------

/// Get the value of a provider.
extension GetProviderExtension<T> on Provider<T> {
  /// {@macro provider-scope.get}
  MaybeProvidedValue<T> get(BuildContext context) {
    return ProviderScope._getOrCreateProvider(context, id: this);
  }
}

/// Observe the value of a [SignalBase] that is in a provider.
extension ObserveSignalInProviderExtension<T extends SignalBase<dynamic>>
    on Provider<T> {
  /// {@macro provider-scope.observe}
  MaybeProvidedValue<T> observe(BuildContext context) {
    return ProviderScope._getOrCreateProvider<T>(
      context,
      id: this,
      listen: true,
    );
  }
}

/// Update the value of a [Signal] that is in a provider.
extension UpdateSignalInProviderExtension<T> on Provider<Signal<T>> {
  /// {@macro provider-scope.update}
  void update(BuildContext context, T Function(T value) callback) {
    if (get(context) case ProvidedValue(value: final signal)) {
      signal.updateValue(callback);
    }
  }
}

/// -------------------------------
/// ProviderWithArgument extensions
/// -------------------------------

/// Get the value of a provider.
extension GetProviderWithArgumentExtension<T, A> on ArgProvider<T, A> {
  /// {@macro provider-scope.get}
  MaybeProvidedValue<T> get(BuildContext context) {
    if (_instance == null) return ProviderNotFound._();
    return ProviderScope._getOrCreateProvider(context, id: _instance!);
  }
}

/// Observe the value of a [SignalBase] that is in a provider with arguments.
extension ObserveSignalInProviderWithArgumentExtension<
    T extends SignalBase<dynamic>, A> on ArgProvider<T, A> {
  /// {@macro provider-scope.observe}
  MaybeProvidedValue<T> observe(BuildContext context) {
    if (_instance == null) return ProviderNotFound._();
    return ProviderScope._getOrCreateProvider<T>(
      context,
      id: _instance!,
      listen: true,
    );
  }
}

/// Update the value of a [SignalBase] that is in a provider with arguments.
///
extension UpdateSignalInProviderWithArgumentExtension<T, A>
    on ArgProvider<Signal<T>, A> {
  /// Safely attempt to update the value of the [Signal<T>] that is in this arg
  /// provider with an argument.
  void update(BuildContext context, T Function(T value) callback) {
    if (get(context) case ProvidedValue(value: final signal)) {
      signal.updateValue(callback);
    }
  }
}
