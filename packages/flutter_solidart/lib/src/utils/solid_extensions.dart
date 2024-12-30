import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Convenience extensions to interact with the [ProviderScope] InheritedModel.
extension ProviderExtensions on BuildContext {
  /// {@macro provider-scope.get}
  P get<P>([Identifier? id]) {
    return ProviderScope.get<P>(this, id);
  }

  /// {@macro provider-scope.maybeGet}
  P? maybeGet<P>([Identifier? id]) {
    return ProviderScope.maybeGet<P>(this, id);
  }

  /// {@macro provider-scope.getElement}
  ProviderElement<P> getElement<P>([Identifier? id]) {
    return ProviderScope.getElement<P>(this, id);
  }

  /// {@macro provider-scope.observe}
  T observe<T extends SignalBase<dynamic>>([Identifier? id]) {
    return ProviderScope.observe<T>(this, id);
  }

  /// {@macro provider-scope.update}
  void update<T>(T Function(T value) callback, [Identifier? id]) {
    return ProviderScope.update<T>(this, callback, id);
  }
}
