import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template provider-map-with-key-arg}
/// Add docs.
/// {@endtemplate}
class ProviderMapWithKeyArg<KA, T> {
  /// {@macro provider-map-with-key-arg}
  ProviderMapWithKeyArg(
    InitProviderValueWithArgFn<KA, T> init, {
    DisposeProviderValueFn<T>? dispose,
    this.lazy = true,
  })  : _init = init,
        _dispose = dispose;

  // ignore: public_member_api_docs
  final Map<KA, ProviderWithArg<KA, T>> providers = {};

  // ignore: public_member_api_docs
  ProviderWithArg<KA, T> operator [](KA key) {
    if (!providers.containsKey(key)) {
      providers[key] =
          ProviderWithArg<KA, T>(_init, dispose: _dispose, lazy: lazy);
    }
    return providers[key]!;
  }

  /// Make the provider creation lazy, defaults to true.
  ///
  /// If this value is true the provider will be [_init]d only
  /// when retrieved from descendants.
  final bool lazy;

  /// The function called to create the element.
  final InitProviderValueWithArgFn<KA, T> _init;

  /// An optional dispose function called when the Solid that created this
  /// provider gets disposed.
  final DisposeProviderValueFn<T>? _dispose;
}
