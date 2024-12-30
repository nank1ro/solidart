import 'package:flutter_solidart/flutter_solidart.dart';

/// {@template provider-context}
/// A [ProviderContext] is a type-safe identifier for [Provider]s.
///
/// To use [ProviderExtensions.observeByCtx] or [ProviderExtensions.updateByCtx]
/// with this provider context, the type [T] must be a [SignalBase].
///
/// A [ProviderContext] is the equivalent of a
/// [Context in SolidJS](https://docs.solidjs.com/concepts/context).
/// {@endtemplate}
class ProviderContext<T> {
  /// {@macro provider-context}
  const ProviderContext();
}
