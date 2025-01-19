import 'package:flutter/widgets.dart';

class _InheritedProviderScopePortal extends InheritedWidget {
  const _InheritedProviderScopePortal({
    required this.mainContext,
    required super.child,
  });

  final BuildContext mainContext;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

/// {@template ProviderScopePortal}
/// Makes the providers of the [mainContext] available in a new widget tree.
///
/// This is useful for accessing providers in modals, because are
/// spawned in a new widget tree.
/// {@endtemplate}
class ProviderScopePortal extends StatelessWidget {
  /// {@macro ProviderScopePortal}
  const ProviderScopePortal({
    super.key,
    required this.mainContext,
    required this.child,
  });

  /// The [mainContext] used to retrieve the providers.
  ///
  /// It should be a descendant of the `ProviderScope` widgets.
  final BuildContext mainContext;

  /// {@macro ProviderScope.child}
  final Widget child;

  /// Retrieve the ProviderScopePortal from the closest ancestor.
  /// Returns the BuildContext, if the widget is found.
  static BuildContext? maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<
            _InheritedProviderScopePortal>()
        ?.widget;
    return (provider as _InheritedProviderScopePortal?)?.mainContext;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProviderScopePortal(
      mainContext: mainContext,
      child: child,
    );
  }
}
