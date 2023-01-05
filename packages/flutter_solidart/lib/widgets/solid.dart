import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

/// Provides [signals] to descendants.
class Solid extends StatefulWidget {
  const Solid({
    super.key,
    this.signals = const {},
    required this.child,
  });

  final Widget child;

  /// All the signals provided to all the descendants of [Solid].
  ///
  /// The key is the signal identifier.
  /// The function must return a signal.
  /// The value is a function in order to create signals lazily only when needed
  final Map<Object, SignalBase<dynamic> Function()> signals;

  @override
  State<Solid> createState() => SolidState();

  static SolidState _findState(
    BuildContext context, {
    required Object id,
    bool listen = false,
  }) {
    final state = _InheritedSolid.inheritFromNearest<_InheritedSolid>(
      context,
      aspect: id,
      listen: listen,
    )?.state;
    if (state == null) {
      throw SolidError(signalId: id);
    }
    return state;
  }

  // Checks that the signal type correspondes to the given type provided.
  // If you created a [Signal] you cannot get it as a [ReadableSignal], and
  // vice versa.
  // This operation is performed only in development mode.
  static void _checkSignalType<S>({
    required SolidState state,
    required Object id,
  }) {
    assert(
      () {
        Type typeOf<X>() => X;
        final t = typeOf<S>();
        final isTypeReadable = t.toString().startsWith('ReadableSignal');
        final isSignalReadable = state.isReadableSignal(id: id);

        // ignore: avoid_positional_boolean_parameters
        String typeString(bool isReadable) {
          return isReadable ? 'ReadableSignal' : 'Signal';
        }

        if (isTypeReadable != isSignalReadable) {
          throw Exception('''
You trying to access a ${typeString(isSignalReadable)} as a ${typeString(isTypeReadable)}
The signal id that caused this issue is $id
''');
        }
        return true;
      }(),
      '',
    );
  }

  /// Obtains the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget.
  static S _getOrCreateSignal<S extends SignalBase<dynamic>>(
    BuildContext context,
    Object id, {
    bool listen = false,
  }) {
    final state = _findState(context, id: id, listen: listen);
    _checkSignalType<S>(state: state, id: id);

    final createdSignal = state._createdSignals[id] as S?;
    // if the signal is not already present, create it lazily
    return createdSignal ?? state.createSignal<S>(id: id);
  }

  /// Obtains the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the signal with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the signal is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the signal is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the signal so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  static S get<S extends SignalBase<dynamic>>(
    BuildContext context,
    Object id,
  ) {
    return _getOrCreateSignal<S>(context, id);
  }

  /// Subscribe to the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget rebuilding the widget when the value exposed by the
  /// [Signal] changes.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the signal with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the signal is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the signal is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Listens to the signal so it causes the widget to rebuild.
  ///
  /// You must call this method only from the `build` method.
  static T observe<T>(
    BuildContext context,
    Object id,
  ) {
    final state = _findState(context, id: id, listen: true);

    // retrieve the signal
    var createdSignal = state._createdSignals[id];

    // if the signal is not already present, create it lazily
    if (createdSignal == null) {
      if (state.isReadableSignal(id: id)) {
        createdSignal = state.createSignal<ReadableSignal<T>>(id: id);
      } else {
        createdSignal = state.createSignal<Signal<T>>(id: id);
      }
    }
    // return the signal value
    return createdSignal.value as T;
  }
}

class SolidState extends State<Solid> {
  // Stores all the created signals.
  final Map<Object, SignalBase<dynamic>> _createdSignals = {};
  // Keeps track of the value of each signals, used to detect which signal
  // updated and to implement fine-grained reactivity.
  Map<Object, dynamic> _signalValues = {};

  @override
  void dispose() {
    // dispose all the created signals
    // no need to dipose readable because they are a subset of a signal
    // and are going to dispose automatically when the signal disposes.
    for (final signal in _createdSignals.values) {
      _stopListeningToSignal(signal);
      signal.dispose();
    }
    _createdSignals.clear();
    _signalValues.clear();
    super.dispose();
  }

  // Indicates is the signal is readable.
  bool isReadableSignal({required Object id}) {
    final isReadableSignal = widget.signals[id] is! Signal<dynamic> Function();
    return isReadableSignal;
  }

  /// Creates a signal with a value of type T:
  S createSignal<S>({required Object id}) {
    if (!isPresent(id)) {
      throw Exception('Cannot find signal with id $id');
    }
    final signal = widget.signals[id]!();
    // store the created signal
    _createdSignals[id] = signal;

    _initializeSignal(signal, id: id);

    return signal as S;
  }

  void _initializeSignal(SignalBase<dynamic> signal, {required Object id}) {
    _listenToSignal(signal);
    signal.onDispose(() {
      _stopListeningToSignal(signal);
    });

    // store the initial signal value
    _signalValues[id] = signal.value;
  }

  /// Used to determine if the requested signal is present for the given
  /// [id]entifier
  bool isPresent(Object id) {
    return widget.signals.containsKey(id);
  }

  void _listenToSignal(SignalBase<dynamic> signal) {
    signal.addListener(_onSignalChange);
  }

  void _stopListeningToSignal(SignalBase<dynamic> signal) {
    signal.removeListener(_onSignalChange);
  }

  void _onSignalChange() {
    setState(() {
      // update the map that keeps track of each signal value
      _signalValues = Map<Object, dynamic>.fromEntries(
        _createdSignals.entries.map(
          (entry) => MapEntry(entry.key, entry.value.value),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSolid(
      state: this,
      signalValues: _signalValues,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty(
        'createdSignals',
        _createdSignals.values,
      ),
    );
  }
}

@immutable
class _InheritedSolid extends InheritedModel<Object> {
  const _InheritedSolid({
    // ignore: unused_element
    super.key,
    required this.state,
    required this.signalValues,
    required super.child,
  });

  final SolidState state;
  final Map<Object, dynamic> signalValues;

  @override
  bool updateShouldNotify(covariant _InheritedSolid oldWidget) {
    return !const DeepCollectionEquality()
        .equals(oldWidget.signalValues, signalValues);
  }

  // Used to determine in which ancestor is the given [aspect].
  @override
  bool isSupportedAspect(Object aspect) {
    return state.isPresent(aspect);
  }

  /// Fine-grained rebuilding of signals that changed value
  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedSolid oldWidget,
    Set<Object> dependencies,
  ) {
    for (final entry in signalValues.entries) {
      // ignore untracked signals
      if (!dependencies.contains(entry.key)) continue;

      final oldSignalValue = oldWidget.signalValues[entry.key];
      if (entry.value != oldSignalValue) {
        return true;
      }
    }
    return false;
  }

  // The following two methods are taken from [InheritedModel] and modified
  // in order to find the first [_InheritedSolid] ancestor that contains the
  // searched Signal id `aspect`.
  // This is a small opmitization that avoids traversing all the [Solid]
  // ancestor.
  // The [result] will be a single InheritedElement of context's type T ancestor
  // that supports the specified model [aspect].
  static InheritedElement? _findNearestModel<T extends InheritedModel<Object>>(
    BuildContext context, {
    required Object aspect,
  }) {
    final model = context.getElementForInheritedWidgetOfExactType<T>();
    // No ancestors of type T found, exit.
    if (model == null) {
      return null;
    }

    assert(model.widget is T, 'The widget must be of type $T');
    final modelWidget = model.widget as T;
    // The model contains the aspect, the ancestor has been found, return it.
    if (modelWidget.isSupportedAspect(aspect)) {
      return model;
    }

    // The aspect has not been found in the current ancestor, go up to other
    // ancestors and try to find it.
    Element? modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    // Return null if we've reached the root.
    if (modelParent == null) {
      return null;
    }

    return _findNearestModel<T>(modelParent!, aspect: aspect);
  }

  /// Makes [context] dependent on the specified [aspect] of an [InheritedModel]
  /// of type T.
  ///
  /// When the given [aspect] of the model changes, the [context] will be
  /// rebuilt if [listen] is set to true.
  ///
  /// The dependencies created by this method target the nearest
  /// [InheritedModel]  ancestor of type T  for which [isSupportedAspect]
  /// returns true.
  ///
  /// If [aspect] is null this method is the same as
  /// `context.dependOnInheritedWidgetOfExactType<T>()` if [listen] is true,
  /// otherwise it's a simple
  /// `context.getElementForInheritedWidgetOfExactType<T>()`.
  ///
  /// If no ancestor of type T exists, null is returned.
  static T? inheritFromNearest<T extends InheritedModel<Object>>(
    BuildContext context, {
    Object? aspect,
    // Whether to listen to the [InheritedModel], defaults to false.
    bool listen = false,
  }) {
    // If no aspect is provided, return the first ancestor found.
    if (aspect == null) {
      if (listen) {
        return context.dependOnInheritedWidgetOfExactType<T>();
      }
      return context.getElementForInheritedWidgetOfExactType<T>()?.widget as T?;
    }

    // Try finding a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel<T>(context, aspect: aspect);
    if (model == null) {
      return null;
    }

    // depend on the inherited element if [listen] is true
    if (listen) {
      context.dependOnInheritedElement(model, aspect: aspect) as T;
    }

    return model.widget as T;
  }
}

class SolidError extends Error {
  SolidError({
    required this.signalId,
  });

  final Object signalId;

  @override
  String toString() {
    return '''
Error: Could not find a Solid containing the given Signal with id $signalId.
    
To fix, please:
          
  * Be sure to have a Solid ancestor, the context used must be below.
  * Provide types to context.get<SignalType>('some-id') 
  * Create signals providing types: 
    ```
    Solid(
      signals: {
        'counter': () => createSignal<int>(0),
      },
    )
    ```
  * The type and id you use to create and consume a signal must match.
  
If none of these solutions work, please file a bug at:
https://github.com/nank1ro/solidart/issues/new
      ''';
  }
}
