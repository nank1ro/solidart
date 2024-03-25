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
  T observe<T, S>([Identifier? id]) {
    return Solid.observe<T, S>(this, id);
  }

  /// Shorthand to observe a [Signal] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<T, Signal<T>>(id)`
  T observeSignal<T>([Identifier? id]) {
    return Solid.observe<T, Signal<T>>(this, id);
  }

  /// Shorthand to observe a [Computed] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<T, Computed<T>>(id)`
  T observeComputed<T>([Identifier? id]) {
    return Solid.observe<T, Computed<T>>(this, id);
  }

  /// Shorthand to observe a [ReadSignal] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<T, ReadSignal<T>>(id)`
  T observeReadSignal<T>([Identifier? id]) {
    return Solid.observe<T, ReadSignal<T>>(this, id);
  }

  /// Shorthand to observe a [ListSignal] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<T, ListSignal<T>>(id)`
  T observeListSignal<T>([Identifier? id]) {
    return Solid.observe<T, ListSignal<T>>(this, id);
  }

  /// Shorthand to observe a [SetSignal] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<T, SetSignal<T>>(id)`
  T observeSetSignal<T>([Identifier? id]) {
    return Solid.observe<T, SetSignal<T>>(this, id);
  }

  /// Shorthand to observe a [MapSignal] with the given types [K] and [V] and
  /// [id].
  ///
  /// Equivalent to `context.observe<V, MapSignal<K, V>>(id)`
  V observeMapSignal<K, V>([Identifier? id]) {
    return Solid.observe<V, MapSignal<K, V>>(this, id);
  }

  /// Shorthand to observe a [Resource] with the given [T] type and [id].
  ///
  /// Equivalent to `context.observe<ResourceState<T>, Resource<T>>(this, id)`
  ResourceState<T> observeResource<T>([Identifier? id]) {
    return Solid.observe<ResourceState<T>, Resource<T>>(this, id);
  }

  /// {@macro solid.update}
  void update<T>(T Function(T value) callback, [Identifier? id]) {
    return Solid.update<T>(this, callback, id);
  }
}
