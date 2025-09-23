import '../_internal/active_element.dart';
import '../core/memoized.dart';

T useMemoized<T>(T Function() factory) {
  final element = getCurrentElement();
  if (element == null) {
    throw StateError('`useMemoized` must be called within a SolidartWidget');
  }

  final prev = element.memoized, current = prev.next;
  if (current != null && current.valueOf<T>()) {
    element.memoized = current;
    return current.value;
  }

  final memoized = SolidartMemoized(
    value: factory(),
    head: prev.head,
    prev: prev,
  );

  element.memoized = prev.next = memoized;
  return memoized.value;
}
