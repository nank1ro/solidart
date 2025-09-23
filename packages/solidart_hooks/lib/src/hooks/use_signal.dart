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
    // TODO: Implement global signal creation
    // This is a call outside of SolidartWidget, assuming it is on a global scale.
    //
    // At present, Dart lacks a detection mechanism to determine whether it is a Widget build, global, or external.
    //
    // Therefore, the authority should be used globally, and there is an alternative solution, which is to detach from SolidartWidget and not allow memory calling, and instead directly use Solidart exported Signal/Calculated/Effects, etc.
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
