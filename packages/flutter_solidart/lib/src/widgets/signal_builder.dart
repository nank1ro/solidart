import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/utils/diagnostic_properties_for_generic.dart';
import 'package:solidart/solidart.dart';

/// {@template signalbuilder}
/// Reacts to the [signal] calling the [builder] each time.
///
/// The [signal] and [builder] arguments must not be null.
/// The [child] is optional but is good practice to use if part of the widget
/// subtree does not depend on the value of the [signal].
/// Example:
///
/// ```dart
/// final counter = createSignal(0);
///
/// @override
/// void dispose() {
///   counter.dispose();
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return SignalBuilder(
///         signal: counter,
///         builder: (context, value, child) {
///           return Text('$value');
///         },
///     );
/// }
/// ```
///
/// If you need to nest multiple `SignalBuilder`s you may also check:
/// - [DualSignalBuilder] to react to __2__ signals at once
/// - [TripleSignalBuilder] to react to __3__ signals at once.
/// {@endtemplate}
class SignalBuilder<T> extends StatefulWidget {
  /// {@macro signalbuilder}
  const SignalBuilder({
    super.key,
    required this.signal,
    required this.builder,
    this.child,
  });

  /// {@template signalbuilder.signal}
  /// The signal whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the signal's value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This signal itself must not be null.
  /// {@endtemplate}
  final SignalBase<T> signal;

  /// {@template signalbuilder.builder}
  /// A [SignalBuilder] which builds a widget depending on the
  /// signal's value.
  ///
  /// Can incorporate a [signal] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  /// {@endtemplate}
  final ValueWidgetBuilder<T> builder;

  /// {@template signalbuilder.child}
  /// A [signal]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree
  /// the [builder] builds depends on the value of the [signal]. For
  /// example, if the [signal] is a [String] and the [builder] simply
  /// returns a [Text] widget with the [String] value.
  /// {@endtemplate}
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<SignalBuilder<T>> {
  late T value;
  DisposeEffect? disposeFn;

  @override
  void initState() {
    super.initState();
    _initializeSignal();
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(SignalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal != widget.signal) {
      disposeFn?.call();
      _initializeSignal();
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    disposeFn?.call();
    super.dispose();
  }

  void _initializeSignal() {
    value = widget.signal.value;
    disposeFn = widget.signal.observe(
      (_, __) => _valueChanged(),
      fireImmediately: false,
    );
  }

  void _valueChanged() {
    setState(() {
      value = widget.signal.value;
    });
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    DiagnosticPropertiesForGeneric(
      value: value,
      name: 'signal',
      properties: properties,
    );
  }
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}

/// The builder function for a [DualSignalBuilder]
typedef DualValueWidgetBuilder<T, U> = Widget Function(
  BuildContext context,
  T firstValue,
  U secondValue,
  Widget? child,
);

/// {@template dualsignalbuilder}
/// The same as [SignalBuilder] but reacts to two signals.
///
/// The usage of [DualSignalBuilder] is preferred over nesting multiple
/// [SignalBuilder]s.
///
/// Docs for [SignalBuilder]:
/// {@macro signalbuilder}
/// {@endtemplate}
class DualSignalBuilder<T, U> extends StatefulWidget {
  /// {@macro dualsignalbuilder}
  const DualSignalBuilder({
    super.key,
    required this.firstSignal,
    required this.secondSignal,
    required this.builder,
    this.child,
  });

  /// {@template signalbuilder.signal}
  final SignalBase<T> firstSignal;

  /// {@template signalbuilder.signal}
  final SignalBase<U> secondSignal;

  /// {@template signalbuilder.builder}
  ///
  /// Called when any of the signals values changes
  final DualValueWidgetBuilder<T, U> builder;

  /// {@macro signalbuilder.child}
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _DualSignalBuilderState<T, U>();
}

class _DualSignalBuilderState<T, U> extends State<DualSignalBuilder<T, U>> {
  late T firstValue;
  late U secondValue;
  DisposeEffect? disposeFn1;
  DisposeEffect? disposeFn2;

  @override
  void initState() {
    super.initState();
    firstValue = widget.firstSignal.value;
    disposeFn1 = widget.firstSignal.observe((_, __) => _valueChanged());
    secondValue = widget.secondSignal.value;
    disposeFn2 = widget.secondSignal.observe((_, __) => _valueChanged());
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(DualSignalBuilder<T, U> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstSignal != widget.firstSignal) {
      disposeFn1?.call();
      firstValue = widget.firstSignal.value;
      disposeFn1 = widget.firstSignal.observe((_, __) => _valueChanged());
    }
    if (oldWidget.secondSignal != widget.secondSignal) {
      disposeFn2?.call();
      secondValue = widget.secondSignal.value;
      disposeFn2 = widget.secondSignal.observe((_, __) => _valueChanged());
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    disposeFn1?.call();
    disposeFn2?.call();
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      firstValue = widget.firstSignal.value;
      secondValue = widget.secondSignal.value;
    });
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    DiagnosticPropertiesForGeneric(
      value: firstValue,
      name: 'firstSignal',
      properties: properties,
    );
    DiagnosticPropertiesForGeneric(
      value: secondValue,
      name: 'secondSignal',
      properties: properties,
    );
  }
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, firstValue, secondValue, widget.child);
  }
}

/// The builder function for a [TripleSignalBuilder]
typedef TripleValueWidgetBuilder<T, U, R> = Widget Function(
  BuildContext context,
  T firstValue,
  U secondValue,
  R thirdValue,
  Widget? child,
);

/// {@template tripesignalbuilder}
/// The same as [SignalBuilder] but reacts to three signals.
///
/// The usage of [TripleSignalBuilder] is preferred over nesting multiple
/// [SignalBuilder]s.
///
/// Docs for [SignalBuilder]:
/// {@macro signalbuilder}
/// {@endtemplate}
class TripleSignalBuilder<T, U, R> extends StatefulWidget {
  /// {@macro tripesignalbuilder}
  const TripleSignalBuilder({
    super.key,
    required this.firstSignal,
    required this.secondSignal,
    required this.thirdSignal,
    required this.builder,
    this.child,
  });

  /// {@template signalbuilder.signal}
  final SignalBase<T> firstSignal;

  /// {@template signalbuilder.signal}
  final SignalBase<U> secondSignal;

  /// {@template signalbuilder.signal}
  final SignalBase<R> thirdSignal;

  /// {@template signalbuilder.builder}
  ///
  /// Called when any of the signals values changes
  final TripleValueWidgetBuilder<T, U, R> builder;

  /// {@macro signalbuilder.child}
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _TripleSignalBuilderState<T, U, R>();
}

class _TripleSignalBuilderState<T, U, R>
    extends State<TripleSignalBuilder<T, U, R>> {
  late T firstValue;
  late U secondValue;
  late R thirdValue;

  DisposeEffect? disposeFn1;
  DisposeEffect? disposeFn2;
  DisposeEffect? disposeFn3;

  @override
  void initState() {
    super.initState();
    firstValue = widget.firstSignal.value;
    disposeFn1 = widget.firstSignal.observe((_, __) => _valueChanged());
    secondValue = widget.secondSignal.value;
    disposeFn2 = widget.secondSignal.observe((_, __) => _valueChanged());
    thirdValue = widget.thirdSignal.value;
    disposeFn3 = widget.thirdSignal.observe((_, __) => _valueChanged());
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(TripleSignalBuilder<T, U, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstSignal != widget.firstSignal) {
      disposeFn1?.call();
      firstValue = widget.firstSignal.value;
      disposeFn1 = widget.firstSignal.observe((_, __) => _valueChanged());
    }
    if (oldWidget.secondSignal != widget.secondSignal) {
      disposeFn2?.call();
      secondValue = widget.secondSignal.value;
      disposeFn2 = widget.secondSignal.observe((_, __) => _valueChanged());
    }
    if (oldWidget.thirdSignal != widget.thirdSignal) {
      disposeFn3?.call();
      thirdValue = widget.thirdSignal.value;
      disposeFn3 = widget.thirdSignal.observe((_, __) => _valueChanged());
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    disposeFn1?.call();
    disposeFn2?.call();
    disposeFn3?.call();
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      firstValue = widget.firstSignal.value;
      secondValue = widget.secondSignal.value;
      thirdValue = widget.thirdSignal.value;
    });
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    DiagnosticPropertiesForGeneric(
      value: firstValue,
      name: 'firstSignal',
      properties: properties,
    );
    DiagnosticPropertiesForGeneric(
      value: secondValue,
      name: 'secondSignal',
      properties: properties,
    );
    DiagnosticPropertiesForGeneric(
      value: thirdValue,
      name: 'thirdSignal',
      properties: properties,
    );
  }
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      firstValue,
      secondValue,
      thirdValue,
      widget.child,
    );
  }
}
