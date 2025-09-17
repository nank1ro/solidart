// ignore_for_file: document_ignores

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:solidart/solidart.dart';

/// {@template SignalBuilderWithoutDependenciesError}
/// This exception would be fired when an effect is created without tracking
/// any dependencies.
/// {@endtemplate}
class SignalBuilderWithoutDependenciesError extends Error {
  @override
  String toString() => '''
SignalBuilderWithoutDependenciesError: SignalBuilder was created without tracking any dependencies.
Make sure to access at least one reactive value (Signal, Computed, etc.) inside the builder callback.
This might happen if inside your `SignalBuilder.builder` method you are returning a `Builder` widget which won't track reactive values because it is considered a different function because it requires another `builder` function.
Or if the signals are disposed (if autoDispose is enabled, which is true by default).
      ''';
}

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

  /// The widget that the [builder] builds.
  @protected
  Widget build(BuildContext context) => builder(context, child);

  /// Creates the [SignalBuilderElement] element.
  @override
  SignalBuilderElement createElement() => SignalBuilderElement(this);
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
  SignalBuilderElement(SignalBuilder super.widget);

  Element? _parent;
  Effect? _effect;

  SignalBuilder get _widget => widget as SignalBuilder;
  Widget? _builtWidget;
  Object? _error;
  bool _firstBuild = true;

  @override
  void mount(Element? parent, Object? newSlot) {
    _parent = parent;
    _effect = Effect(
      _invalidate,
      autoDispose: false,
      onError: (error) {
        final effectiveError = switch (error) {
          EffectWithoutDependenciesError() =>
            SignalBuilderWithoutDependenciesError(),
          _ => error,
        };
        _error = effectiveError;
      },
      detach: true,
      autorun: false,
    );
    // mounting intentionally after effect is initialized and widget is built
    super.mount(parent, newSlot);
  }

  // coverage:ignore-start
  @override
  void update(SignalBuilder newWidget) {
    super.update(newWidget);
    _effect?.run();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstBuild) return;
    _effect?.run();
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

    if (_firstBuild) {
      _firstBuild = false;
      _effect?.run();
    }

    // ignore: only_throw_errors
    if (_error != null) throw _error!;
    try {
      return _builtWidget!;
    } finally {
      reactiveSystem.activeSub = prevSub;
    }
  }
}

class SignalBuilder2<T extends Widget> extends StatefulWidget {
  const SignalBuilder2({
    super.key,
    required this.builder,
    this.child,
  });

  /// The widget to rebuild when any signals change
  final T Function(BuildContext context, Widget? child) builder;

  final Widget? child;

  @override
  State<SignalBuilder2<T>> createState() => _SignalBuilder2State<T>();
}

class _SignalBuilder2State<T extends Widget> extends State<SignalBuilder2<T>> {
  late final result = Computed(() {
    print('SignalBuilder computed');
    return widget.builder(context, widget.child);
  }, autoDispose: true);
  bool _init = true;

  @override
  void initState() {
    super.initState();
    result.onDispose(() {
      print('SignalBuilder computed disposed');
    });
  }

  // coverage:ignore-start
  @override
  void reassemble() {
    super.reassemble();
    print('SignalBuilder reassemble');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      result.run();
      if (mounted) setState(() {});
      result.value;
    });
  }
  // coverage:ignore-end

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('SignalBuilder didChangeDependencies');
    if (_init) {
      // Called on first build (we do not need to rebuild yet)
      _init = false;
      return;
    }
    result.run();
  }

  @override
  void didUpdateWidget(covariant SignalBuilder2<T> oldWidget) {
    print('SignalBuilder didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      result.run();
    }
  }

  @override
  void dispose() {
    result.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SignalBuilder build');
    return result.value;
  }
}
