import 'package:flutter/material.dart';

class _InheritedProviderScopeValue extends InheritedWidget {
  const _InheritedProviderScopeValue({
    required this.mainContext,
    required super.child,
  });

  final BuildContext mainContext;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

/// {@template ProviderScopeValue}
/// Makes the providers of the [mainContext] available in a new widget tree.
///
/// This is useful for accessing providers in modals, because are
/// spawned in a new widget tree.
/// {@endtemplate}
class ProviderScopeValue extends StatelessWidget {
  /// {@macro ProviderScopeValue}
  const ProviderScopeValue({
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

  static BuildContext? maybeOf(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<_InheritedProviderScopeValue>()
        ?.widget;
    return (provider as _InheritedProviderScopeValue?)?.mainContext;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProviderScopeValue(
      mainContext: mainContext,
      child: child,
    );
  }
}
