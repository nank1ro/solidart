part of '../widgets/provider_scope.dart';

/// Get the value of a provider.
extension InjectExtensionProviderId<T> on Provider<T> {
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

/// Get the value of a provider.
extension InjectExtensionArgProvider<T, A> on ArgProvider<T, A> {
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
    final instance = _instances[A];
    if (instance == null) return null;

    return ProviderScope._getOrCreateProvider(context, id: instance);
  }
}

/// Observe the value of a [SignalBase] that is in a provider.
extension ObserveExtensionProviderId<T extends SignalBase<dynamic>>
    on Provider<T> {
  /// {@macro provider-scope.observe}
  T observe(BuildContext context) {
    final provider = maybeObserve(context);
    if (provider == null) throw ProviderError<T>(this);
    return provider;
  }

  /// {@macro provider-scope.maybeObserve}
  T? maybeObserve(BuildContext context) {
    return ProviderScope._getOrCreateProvider<T>(
      context,
      id: this,
      listen: true,
    );
  }
}

/// Observe the value of a [Signal] that is in a provider.
extension UpdateExtensionProviderId<T> on Provider<Signal<T>> {
  /// {@macro provider-scope.update}
  void update(BuildContext context, T Function(T value) callback) {
    get(context).updateValue(callback);
  }

  /// {@macro provider-scope.maybeUpdate}
  void maybeUpdate(BuildContext context, T Function(T value) callback) {
    final provider = maybeGet(context);
    if (provider == null) return;
    provider.updateValue(callback);
  }
}
