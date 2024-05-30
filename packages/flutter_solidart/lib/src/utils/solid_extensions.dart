import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Convenience extensions to interact with the [Solid] InheritedModel.
extension SolidExtensions on BuildContext {
  /// {@macro solid.get}
  P get<P>([Identifier? id]) {
    return Solid.get<P>(this, id);
  }

  /// {@macro solid.maybeGet}
  P? maybeGet<P>([Identifier? id]) {
    return Solid.maybeGet<P>(this, id);
  }

  /// {@macro solid.getElement}
  SolidElement<P> getElement<P>([Identifier? id]) {
    return Solid.getElement<P>(this, id);
  }

  /// {@macro solid.observe}
  T observe<T extends SignalBase<dynamic>>([Identifier? id]) {
    return Solid.observe<T>(this, id);
  }

  /// {@macro solid.update}
  void update<T>(T Function(T value) callback, [Identifier? id]) {
    return Solid.update<T>(this, callback, id);
  }
}
