import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template provider-map}
/// Add docs.
/// {@endtemplate}
class ProviderMapWithArg<K, A, T> {
  /// {@macro provider-map}
  ProviderMapWithArg(
    InitProviderValueWithArgFn<A, T> init, {
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  })  : _init = init,
        _dispose = dispose;

  // ignore: public_member_api_docs
  final Map<K, ProviderWithArg<A, T>> providers = {};

  // ignore: public_member_api_docs
  ProviderWithArg<A, T> operator [](K key) {
    if (!providers.containsKey(key)) {
      providers[key] =
          ProviderWithArg<A, T>(_init, dispose: _dispose, lazy: lazy);
    }
    return providers[key]!;
  }

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_init]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// The function called to create the element.
  final InitProviderValueWithArgFn<A, T> _init;

  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  final DisposeProviderValueFn<T>? _dispose;
}
