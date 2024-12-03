import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/src/widgets/solid.dart';

/// Error thrown when there are multiple SolidOverride widgets in the widget
/// tree.
class MultipleSolidOverrideError extends Error {
  @override
  String toString() =>
      'You cannot have multiple SolidOverride widgets in the widget tree.';
}

/// {@template solid_override}
/// Overrides providers of the [Solid] widget.
///
/// This is useful for widget testing where mocking is needed.
/// {@endtemplate}
class SolidOverride extends StatefulWidget {
  /// {@macro solid_override}
  const SolidOverride({
    super.key,
    required this.providers,
    this.builder,
    this.child,
  });

  /// The widget child that gets access to the [providers].
  final Widget? child;

  /// The widget builder that gets access to the [providers].
  final WidgetBuilder? builder;

  /// All the overriden providers provided to all the descendants of [Solid].
  final List<SolidElement<dynamic>> providers;

  /// Returns the [SolidOverrideState] of the [SolidOverride] widget.
  /// Throws an [AssertionError] if the [SolidOverride] widget is not found in
  /// the ancestor widget tree.
  static SolidOverrideState of(BuildContext context) {
    final inherited = maybeOf(context);
    if (inherited == null) {
      throw FlutterError(
        '''Could not find SolidOverride InheritedWidget in the ancestor widget tree.''',
      );
    }
    return inherited;
  }

  /// Returns the [SolidOverrideState] of the [SolidOverride] widget.
  /// Returns null if the [SolidOverride] widget is not found in the ancestor
  /// widget tree.
  static SolidOverrideState? maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<_InheritedSolidOverride>()
        ?.widget;
    return (provider as _InheritedSolidOverride?)?.state;
  }

  @override
  State<SolidOverride> createState() => SolidOverrideState();
}

/// The state of the [SolidOverride] widget.
class SolidOverrideState extends State<SolidOverride> {
  /// The key of the [SolidState] of the [SolidOverride] widget.
  final _solidStateKey = GlobalKey<SolidState>();

  /// The [SolidState] of the [SolidOverride] widget.
  SolidState get solidState => _solidStateKey.currentState!;

  @override
  Widget build(BuildContext context) {
    if (SolidOverride.maybeOf(context) != null) {
      throw MultipleSolidOverrideError();
    }
    return _InheritedSolidOverride(
      state: this,
      child: Solid(
        key: _solidStateKey,
        providers: widget.providers,
        builder: widget.builder,
        child: widget.child,
      ),
    );
  }
}

class _InheritedSolidOverride extends InheritedWidget {
  const _InheritedSolidOverride({
    required super.child,
    required this.state,
  });

  /// The data to be provided
  final SolidOverrideState state;

  @override
  bool updateShouldNotify(covariant _InheritedSolidOverride oldWidget) {
    return false;
  }
}
