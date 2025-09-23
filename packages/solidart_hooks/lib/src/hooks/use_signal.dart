import 'package:solidart/solidart.dart';

import '../_internal/active_element.dart';
import 'use_memoized.dart';

/// {@macro signal}
Signal<T> useSignal<T>(
  T initialValue, {
  String? name,
  bool? equals,
  bool autoDispose = false,
  bool Function(T? a, T? b) comparator = identical,
  bool? trackInDevTools,
  bool? trackPreviousValue,
}) {
  if (getCurrentElement() == null) {
    // Called outside SolidartWidget: treat as a global effect.
    // Dart can’t reliably detect build/global/external contexts.
    // Prefer using Solidart’s Effect directly when not in a SolidartWidget.
    return Signal(
      initialValue,
      name: name,
      equals: equals,
      autoDispose: autoDispose,
      comparator: comparator,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    );
  }

  return useMemoized(
    () => Signal(
      initialValue,
      name: name,
      equals: equals,
      autoDispose: autoDispose,
      comparator: comparator,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
  );
}
