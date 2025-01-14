part of '../widgets/provider_scope.dart';

/// -------------------------------
/// Provider extensions
/// -------------------------------

/// Get the value of a provider.
extension GetProviderExtension<T> on Provider<T> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) throw ProviderError<T>(this);
    return provider;
  }

  /// {@macro provider-scope.maybeGet}
  T? maybeGet(BuildContext context) {
    return ProviderScope._getOrCreateProvider(context, id: this);
  }
}

/// Update the value of a [Signal] that is in a provider.
extension UpdateSignalInProviderExtension<T> on Provider<Signal<T>> {
  /// {@macro provider-scope.update}
  void update(BuildContext context, T Function(T value) callback) {
    get(context).updateValue(callback);
  }

  /// {@macro provider-scope.maybeUpdate}
  void maybeUpdate(BuildContext context, T Function(T value) callback) {
    maybeGet(context)?.updateValue(callback);
  }
}

/// -------------------------------
/// ProviderWithArgument extensions
/// -------------------------------

/// Get the value of a provider.
extension GetProviderWithArgumentExtension<T, A> on ArgProvider<T, A> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) {
      throw ProviderWithoutScopeError(this);
    }
    return provider;
  }

  /// {@macro provider-scope.maybeGet}
  T? maybeGet(BuildContext context) {
    if (_instance == null) return null;

    return ProviderScope._getOrCreateProvider(context, id: _instance!);
  }
}

/// Update the value of a [SignalBase] that is in a provider with arguments.
///
extension UpdateSignalInProviderWithArgumentExtension<T, A>
    on ArgProvider<Signal<T>, A> {
  /// Update the value of a [Signal<T>] that is in this arg provider with an
  /// argument.
  void update(BuildContext context, T Function(T value) callback) {
    get(context).updateValue(callback);
  }

  /// Safely attempt to update the value of the [Signal<T>] that is in this arg
  /// provider with an argument.
  void maybeUpdate(BuildContext context, T Function(T value) callback) {
    maybeGet(context)?.updateValue(callback);
  }
}
