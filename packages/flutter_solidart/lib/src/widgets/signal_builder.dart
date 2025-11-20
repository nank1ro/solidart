// ignore_for_file: document_ignores

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:solidart/solidart.dart';

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
class SignalBuilder extends StatelessWidget {
  /// {@macro signal-builder-element}
  const SignalBuilder({super.key, required this.builder, this.child});

  /// {@template signalbuilder.builder}
  /// A [SignalBuilder] which builds a widget depending on the
  /// values of the signals found in the [builder].
  ///
  /// Must not be null.
  /// {@endtemplate}
  final Widget Function(BuildContext context, Widget? child) builder;

  /// {@template signalbuilder.child}
  /// A signal-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree
  /// the [builder] builds depends on the value of the signals.
  /// If you have a widget in the subtree that do not depend on the values of
  /// the signals, use this argument, because it won't be rebuilded.
  /// {@endtemplate}
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);

  @override
  @internal
  StatelessElement createElement() => _SignalBuilderElement(this);
}

class _SignalBuilderElement extends StatelessElement {
  _SignalBuilderElement(SignalBuilder super.widget);

  late final effect = Effect(
    scheduler,
    detach: true,
    autoDispose: false,
    autorun: false,
  );

  void scheduler() {
    if (dirty) return;
    markNeedsBuild();
  }

  @override
  void unmount() {
    effect.dispose();
    super.unmount();
  }

  @override
  Widget build() {
    final prevSub = reactiveSystem.activeSub;
    // ignore: invalid_use_of_protected_member
    final node = reactiveSystem.activeSub = effect.subscriber;

    try {
      final built = super.build();
      if (SolidartConfig.assertSignalBuilderWithoutDependencies) {
        assert(node.deps != null, '''
SignalBuilder must detect at least one Signal, Computed, or Resource during the build.
This may mean your reactive values were disposed. 
You can disable this check by setting `SolidartConfig.assertSignalBuilderWithoutDependencies = false` before `runApp()`'
          ''');
      }
      // ignore: invalid_use_of_internal_member
      effect.setDependencies(node);

      return built;
    } finally {
      reactiveSystem.activeSub = prevSub;
    }
  }
}
