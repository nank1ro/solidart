part of '../widgets/provider_scope.dart';

/// Error thrown when there are multiple ProviderScopeOverride widgets in the
/// widget tree.
class MultipleProviderScopeOverrideError extends Error {
  @override
  String toString() =>
      'You cannot have multiple ProviderScopeOverride widgets in the widget '
      'tree.';
}

/// {@template solid_override}
/// Overrides providers of the [ProviderScope] widget.
///
/// This is useful for widget testing where mocking is needed.
/// {@endtemplate}
class ProviderScopeOverride extends StatefulWidget {
  /// {@macro solid_override}
  const ProviderScopeOverride({
    super.key,
    required this.overrides,
    required this.child,
  });

  /// The widget child that gets access to the [overrides].
  final Widget child;

  /// All the overriden providers provided to all the descendants of
  /// [ProviderScope].
  final List<Override> overrides;

  /// Returns the [ProviderScopeOverrideState] of the [ProviderScopeOverride]
  /// widget.
  /// Throws an [AssertionError] if the [ProviderScopeOverride] widget is not
  /// found in the ancestor widget tree.
  static ProviderScopeOverrideState of(BuildContext context) {
    final inherited = maybeOf(context);
    if (inherited == null) {
      throw FlutterError(
        '''Could not find ProviderScopeOverride InheritedWidget in the ancestor widget tree.''',
      );
    }
    return inherited;
  }

  /// Returns the [ProviderScopeOverrideState] of the [ProviderScopeOverride]
  /// widget.
  /// Returns null if the [ProviderScopeOverride] widget is not found in the
  /// ancestor widget tree.
  static ProviderScopeOverrideState? maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<
            _InheritedProviderScopeOverride>()
        ?.widget;
    return (provider as _InheritedProviderScopeOverride?)?.state;
  }

  @override
  State<ProviderScopeOverride> createState() => ProviderScopeOverrideState();
}

/// The state of the [ProviderScopeOverride] widget.
class ProviderScopeOverrideState extends State<ProviderScopeOverride> {
  /// The key of the [ProviderScopeState] of the [ProviderScopeOverride] widget.
  final _solidStateKey = GlobalKey<ProviderScopeState>();

  /// The [ProviderScopeState] of the [ProviderScopeOverride] widget.
  ProviderScopeState get solidState => _solidStateKey.currentState!;

  @override
  Widget build(BuildContext context) {
    if (ProviderScopeOverride.maybeOf(context) != null) {
      throw MultipleProviderScopeOverrideError();
    }
    return _InheritedProviderScopeOverride(
      state: this,
      child: ProviderScope._fromOverrides(
        key: _solidStateKey,
        overrides: widget.overrides,
        child: widget.child,
      ),
    );
  }
}

class _InheritedProviderScopeOverride extends InheritedWidget {
  const _InheritedProviderScopeOverride({
    required super.child,
    required this.state,
  });

  /// The data to be provided
  final ProviderScopeOverrideState state;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant _InheritedProviderScopeOverride oldWidget) {
    return false;
  }
  // coverage:ignore-end
}
