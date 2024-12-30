import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Convenience extensions to interact with the [ProviderScope] InheritedModel.
extension ProviderExtensions on BuildContext {
  /// {@macro provider-scope.get}
  P get<P>([Identifier? id]) {
    return ProviderScope.get<P>(this, id);
  }

  /// {@macro provider-scope.get}
  P getByCtx<P>(ProviderContext<P> providerContext) => get<P>(providerContext);

  /// {@macro provider-scope.maybeGet}
  P? maybeGet<P>([Identifier? id]) {
    return ProviderScope.maybeGet<P>(this, id);
  }

  /// {@macro provider-scope.maybeGet}
  P? maybeGetByCtx<P>(ProviderContext<P> providerContext) =>
      maybeGet<P>(providerContext);

  /// {@macro provider-scope.getElement}
  ProviderElement<P> getElement<P>([Identifier? id]) {
    return ProviderScope.getElement<P>(this, id);
  }

  /// {@macro provider-scope.getElement}
  ProviderElement<P> getElementByCtx<P>(ProviderContext<P> providerContext) =>
      getElement<P>(providerContext);

  /// {@macro provider-scope.observe}
  T observe<T extends SignalBase<dynamic>>([Identifier? id]) {
    return ProviderScope.observe<T>(this, id);
  }

  /// {@macro provider-scope.observe}
  T observeByCtx<T extends SignalBase<dynamic>>(
    ProviderContext<T> providerContext,
  ) =>
      observe<T>(providerContext);

  /// {@macro provider-scope.update}
  void update<T>(T Function(T value) callback, [Identifier? id]) {
    return ProviderScope.update<T>(this, callback, id);
  }

  /// Convenience method to update a `Signal` value.
  ///
  /// You can use it to update a signal value, e.g:
  /// ```dart
  /// const myCounter = ProviderContext<Signal<int>>();
  ///
  /// // some function inside some widget
  /// someFn(BuildContext context) {
  ///   context.updateByCtx(myCounter, (value) => value * 2);
  /// }
  /// ```
  /// This is equal to:
  /// ```dart
  /// // retrieve the signal
  /// final signal = context.getByCtx(myCounter);
  /// // update the signal
  /// signal.update((value) => value * 2);
  /// ```
  /// but shorter when you don't need the signal for anything else.
  ///
  /// WARNING: Supports only the `Signal` type
  void updateByCtx<T>(
    T Function(T value) callback,
    ProviderContext<T> providerContext,
  ) =>
      update(callback, providerContext);
}
