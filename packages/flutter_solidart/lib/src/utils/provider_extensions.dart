part of '../widgets/provider_scope.dart';

/// -------------------------------
/// Provider extensions
/// -------------------------------

/// Get the value of a provider.
extension GetProviderExtension<T extends Object> on Provider<T> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) throw ProviderWithoutScopeError(this);
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
extension GetProviderWithArgumentExtension<T extends Object, A>
    on ArgProvider<T, A> {
  /// {@macro provider-scope.get}
  T get(BuildContext context) {
    final provider = maybeGet(context);
    if (provider == null) {
      throw ArgProviderWithoutScopeError(this);
    }
    return provider;
  }

  /// {@macro provider-scope.maybeGet}
  T? maybeGet(BuildContext context) {
    return ProviderScope._getOrCreateArgProvider(context, id: this);
  }
}
