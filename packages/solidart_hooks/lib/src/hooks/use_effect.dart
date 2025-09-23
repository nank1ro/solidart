import 'package:solidart/solidart.dart';

import '../_internal/active_element.dart';
import 'use_memoized.dart';

@Deprecated('useSolidartEffect is deprecated. Use useEffect instead.')
const useSolidartEffect = useEffect;

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
    // TODO: Implement global signal creation
    // This is a call outside of SolidartWidget, assuming it is on a global scale.
    //
    // At present, Dart lacks a detection mechanism to determine whether it is a Widget build, global, or external.
    //
    // Therefore, the authority should be used globally, and there is an alternative solution, which is to detach from SolidartWidget and not allow memory calling, and instead directly use Solidart exported Signal/Calculated/Effects, etc.
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
