part of '../widgets/solid.dart';

/// {@template provider-id}
/// A [ProviderId] is a type-safe identifier for [Provider]s. It is not only
/// an ID: due to its generic type, it ensures
///
/// A [ProviderId] is the equivalent of a
/// [Context in SolidJS](https://docs.solidjs.com/concepts/context).
/// {@endtemplate}
class ProviderId<T> {
  /// {@macro provider-id}
  ProviderId();

  //! NB: do not make the constructor `const`, since that would give the same
  //! hash code to different instances of `ProviderId` with the same generic
  //! type.

  /// Generates a new provider.
  ///
  /// Type inference ensures that the [init] and [dispose] callbacks are
  /// type-checked at compile time.
  Provider<T> createProvider({
    required InitProviderValueFn<T> init,
    DisposeProviderValueFn<T>? dispose,
    bool lazy = true,
  }) =>
      Provider._(this, init: init, dispose: dispose, lazy: lazy);

  /// This is a bit of a hack: it is used in [ProviderScope.value] and
  /// [ProviderScope.values].
  /// If [ProviderScope._getProvider] were used directly by the two
  /// constructors, the type will be wrongly inferred to `dynamic` instead
  /// of the precise type, and it would result in runtime exception.
  Provider<T> _getProvider(
    BuildContext context,
  ) {
    return ProviderScope._getProvider<T>(context, this);
  }

  /// Returns the type of the value
  Type get _valueType => T;
}
