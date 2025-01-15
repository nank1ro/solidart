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
