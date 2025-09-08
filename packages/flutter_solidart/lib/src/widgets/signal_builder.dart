// ignore_for_file: document_ignores

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:solidart/solidart.dart';

/// The [SignalBuilder] function used to build the widget tracking the signals.
typedef SignalBuilderFn = Widget Function(
  BuildContext context,
  Widget? child,
);

/// A callback that is called when an error occurs.
typedef SignalBuilderOnError = void Function(Object error);

/// {@template signalbuilder}
/// Reacts to the signals automatically found in the [builder] function.
///
/// The [builder] argument must not be null.
/// The [child] is optional but is good practice to use if part of the widget
/// subtree does not depend on the values of the signals.
/// The [onError] callback is optional and is called when an error occurs in the
/// [builder] function.
/// Example:
///
/// ```dart
/// final counter = Signal(0);
///
/// @override
/// void dispose() {
///   counter.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return SignalBuilder(
///     builder: (context, child) {
///       return Text('${counter.value}');
///     },
///   );
/// }
/// ```
/// {@endtemplate}
class SignalBuilder extends Widget {
  /// {@macro signalbuilder}
  const SignalBuilder({
    super.key,
    required this.builder,
    this.onError,
    this.child,
  });

  /// {@template signalbuilder.builder}
  /// A [SignalBuilder] which builds a widget depending on the
  /// values of the signals found in the [builder].
  ///
  /// Must not be null.
  /// {@endtemplate}
  final SignalBuilderFn builder;

  /// {@template signalbuilder.child}
  /// A signal-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree
  /// the [builder] builds depends on the value of the signals.
  /// If you have a widget in the subtree that do not depend on the values of
  /// the signals, use this argument, because it won't be rebuilded.
  /// {@endtemplate}
  final Widget? child;

  /// {@template signalbuilder.onerror}
  /// An optional callback that is called when an error occurs in the underlying
  /// effect when running [builder].
  /// {@endtemplate}
  final SignalBuilderOnError? onError;

  /// The widget that the [builder] builds.
  @protected
  Widget build(BuildContext context) => builder(context, child);

  /// Creates the [SignalBuilderElement] element.
  @override
  SignalBuilderElement createElement() =>
      SignalBuilderElement(this, onError: onError);
}

/// {@template signal-builder-element}
/// The [SignalBuilder] widget's [Element] subclass.
///
/// Automatically tracks and reacts to the signals found in the
/// [SignalBuilder.builder] function
///
/// This class is not meant to be used directly.
/// Use [SignalBuilder] instead.
/// {@endtemplate}
class SignalBuilderElement extends ComponentElement {
  /// {@macro signal-builder-element}
  SignalBuilderElement(
    SignalBuilder super.widget, {
    this.onError,
  });

  /// {@macro signalbuilder.onerror}
  final void Function(Object error)? onError;

  Element? _parent;
  Effect? _effect;

  SignalBuilder get _widget => widget as SignalBuilder;
  Widget? _builtWidget;
  Object? _error;

  @override
  void mount(Element? parent, Object? newSlot) {
    _parent = parent;
    _effect = Effect(
      _invalidate,
      autoDispose: false,
      onError: onError,
      detach: true,
      autorun: false,
    );
    _effect!.run();
    // mounting intentionally after effect is initialized and widget is built
    super.mount(parent, newSlot);
  }

  // coverage:ignore-start
  @override
  void update(SignalBuilder newWidget) {
    super.update(newWidget);
    assert(widget == newWidget, 'The widget and newWidget must be the same');
    rebuild(force: true);
  }
  // coverage:ignore-end

  @override
  void unmount() {
    _effect?.dispose();
    _effect = null;
    super.unmount();
  }

  // coverage:ignore-start
  Future<void> _invalidate() async {
    try {
      _builtWidget = _widget.build(_parent!);
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      _error = error;
    }

    if (_shouldWaitScheduler) {
      await SchedulerBinding.instance.endOfFrame;
      // If the effect is disposed after this frame, avoid rebuilding
      if (_effect!.disposed) return;
    }
    markNeedsBuild();
  }

  bool get _shouldWaitScheduler {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    return schedulerPhase != SchedulerPhase.idle &&
        schedulerPhase != SchedulerPhase.postFrameCallbacks;
  }
  // coverage:ignore-end

  @override
  Widget build() {
    final prevSub = reactiveSystem.activeSub;
    // ignore: invalid_use_of_protected_member
    reactiveSystem.activeSub = _effect?.subscriber;

    // ignore: only_throw_errors
    if (_error != null) throw _error!;
    try {
      return _builtWidget!;
    } finally {
      reactiveSystem.activeSub = prevSub;
    }
  }
}
