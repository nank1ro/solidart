import 'package:solidart/solidart.dart';

import '../_internal/active_element.dart';
import 'use_memoized.dart';

// Create a signal effect
Effect useEffect(
  void Function() run, {
  void Function(Object error)? onError,
  String? name,
  Duration? delay,
  bool? autoDispose,
  bool? detach,
  bool? autorun,
}) {
  if (getCurrentElement() == null) {
    // Called outside SolidartWidget: treat as a global effect.
    // Dart can’t reliably detect build/global/external contexts.
    // Prefer using Solidart’s Effect directly when not in a SolidartWidget.
    return Effect(
      run,
      onError: onError,
      name: name,
      delay: delay,
      autoDispose: autoDispose,
      detach: detach,
      autorun: autorun,
    );
  }

  return useMemoized(
    () => Effect(
      run,
      onError: onError,
      name: name,
      delay: delay,
      autoDispose: autoDispose,
      detach: detach,
      autorun: autorun,
    ),
  );
}
