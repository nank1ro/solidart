import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/utils/diagnostic_properties_for_generic.dart';
import 'package:solidart/solidart.dart';

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
/// - `DualSignalBuilder` to react to __2__ signals at once
/// - `TripleSignalBuilder` to react to __3__ signals at once.
class SignalBuilder<T> extends StatefulWidget {
  const SignalBuilder({
    super.key,
    required this.signal,
    required this.builder,
    this.child,
  });

  /// The [Signal] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [Signal]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [signal] itself must not be null.
  final SignalBase<T> signal;

  /// A [SignalBuilder] which builds a widget depending on the
  /// [signal]'s value.
  ///
  /// Can incorporate a [signal] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ValueWidgetBuilder<T> builder;

  /// A [signal]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree
  /// the [builder] builds depends on the value of the [signal]. For
  /// example, if the [signal] is a [String] and the [builder] simply
  /// returns a [Text] widget with the [String] value.
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _SignalBuilderState<T>();
}

class _SignalBuilderState<T> extends State<SignalBuilder<T>> {
  late T value;

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
      oldWidget.signal.removeListener(_valueChanged);
      _initializeSignal();
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    widget.signal.removeListener(_valueChanged);
    super.dispose();
  }

  void _initializeSignal() {
    value = widget.signal.value;
    widget.signal.addListener(_valueChanged);
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

typedef DualValueWidgetBuilder<T, U> = Widget Function(
  BuildContext context,
  T firstValue,
  U secondValue,
  Widget? child,
);

class DualSignalBuilder<T, U> extends StatefulWidget {
  const DualSignalBuilder({
    super.key,
    required this.firstSignal,
    required this.secondSignal,
    required this.builder,
    this.child,
  });

  final SignalBase<T> firstSignal;

  final SignalBase<U> secondSignal;

  final DualValueWidgetBuilder<T, U> builder;

  final Widget? child;

  @override
  State<StatefulWidget> createState() => _DualSignalBuilderState<T, U>();
}

class _DualSignalBuilderState<T, U> extends State<DualSignalBuilder<T, U>> {
  late T firstValue;
  late U secondValue;

  @override
  void initState() {
    super.initState();
    firstValue = widget.firstSignal.value;
    widget.firstSignal.addListener(_valueChanged);
    secondValue = widget.secondSignal.value;
    widget.secondSignal.addListener(_valueChanged);
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(DualSignalBuilder<T, U> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstSignal != widget.firstSignal) {
      oldWidget.firstSignal.removeListener(_valueChanged);
      firstValue = widget.firstSignal.value;
      widget.firstSignal.addListener(_valueChanged);
    }
    if (oldWidget.secondSignal != widget.secondSignal) {
      oldWidget.secondSignal.removeListener(_valueChanged);
      secondValue = widget.secondSignal.value;
      widget.secondSignal.addListener(_valueChanged);
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    widget.firstSignal.removeListener(_valueChanged);
    widget.secondSignal.removeListener(_valueChanged);
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

typedef TripleValueWidgetBuilder<T, U, R> = Widget Function(
  BuildContext context,
  T firstValue,
  U secondValue,
  R thirdValue,
  Widget? child,
);

class TripleSignalBuilder<T, U, R> extends StatefulWidget {
  const TripleSignalBuilder({
    super.key,
    required this.firstSignal,
    required this.secondSignal,
    required this.thirdSignal,
    required this.builder,
    this.child,
  });

  final SignalBase<T> firstSignal;

  final SignalBase<U> secondSignal;

  final SignalBase<R> thirdSignal;

  final TripleValueWidgetBuilder<T, U, R> builder;

  final Widget? child;

  @override
  State<StatefulWidget> createState() => _TripleSignalBuilderState<T, U, R>();
}

class _TripleSignalBuilderState<T, U, R>
    extends State<TripleSignalBuilder<T, U, R>> {
  late T firstValue;
  late U secondValue;
  late R thirdValue;

  @override
  void initState() {
    super.initState();
    firstValue = widget.firstSignal.value;
    widget.firstSignal.addListener(_valueChanged);
    secondValue = widget.secondSignal.value;
    widget.secondSignal.addListener(_valueChanged);
    thirdValue = widget.thirdSignal.value;
    widget.thirdSignal.addListener(_valueChanged);
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(TripleSignalBuilder<T, U, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstSignal != widget.firstSignal) {
      oldWidget.firstSignal.removeListener(_valueChanged);
      firstValue = widget.firstSignal.value;
      widget.firstSignal.addListener(_valueChanged);
    }
    if (oldWidget.secondSignal != widget.secondSignal) {
      oldWidget.secondSignal.removeListener(_valueChanged);
      secondValue = widget.secondSignal.value;
      widget.secondSignal.addListener(_valueChanged);
    }
    if (oldWidget.thirdSignal != widget.thirdSignal) {
      oldWidget.thirdSignal.removeListener(_valueChanged);
      thirdValue = widget.thirdSignal.value;
      widget.thirdSignal.addListener(_valueChanged);
    }
  }
  // coverage:ignore-end

  @override
  void dispose() {
    widget.firstSignal.removeListener(_valueChanged);
    widget.secondSignal.removeListener(_valueChanged);
    widget.thirdSignal.removeListener(_valueChanged);
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
