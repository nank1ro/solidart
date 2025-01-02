import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template provider-map}
/// Add docs.
/// {@endtemplate}
class ProviderMap<K, T> {
  /// {@macro provider-map}
  ProviderMap(
    InitProviderValueFn<T> init, {
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  })  : _init = init,
        _dispose = dispose;

  // ignore: public_member_api_docs
  final Map<K, Provider<T>> providers = {};

  // ignore: public_member_api_docs
  Provider<T> operator [](K key) {
    if (!providers.containsKey(key)) {
      providers[key] = Provider<T>(_init, dispose: _dispose, lazy: lazy);
    }
    return providers[key]!;
  }

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_init]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// The function called to create the element.
  final InitProviderValueFn<T> _init;

  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  final DisposeProviderValueFn<T>? _dispose;
}
