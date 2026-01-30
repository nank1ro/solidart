part of '../solidart.dart';

/// A signal that starts uninitialized until first set.
///
/// This is the concrete type behind [Signal.lazy]. Reading [value] before the
/// first assignment throws [StateError].
///
/// ```dart
/// final lazy = Signal.lazy<int>();
/// lazy.value = 1;
/// print(lazy.value); // 1
/// ```
class LazySignal<T> extends Signal<T> {
  /// Creates a lazy signal.
  LazySignal({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : super._internal(
         const None(),
         name: name,
         autoDispose: autoDispose,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  @override
  bool get isInitialized => currentValue is Some<T>;

  @override
  T get value {
    if (isInitialized || pendingValue is Some<T>) {
      return super.value;
    }
    throw StateError(
      'LazySignal is not initialized, please call `.value = <newValue>` first.',
    );
  }

  @override
  bool didUpdate() {
    if (!isInitialized) {
      flags = system.ReactiveFlags.mutable;
      currentValue = pendingValue;
      return true;
    }

    return super.didUpdate();
  }
}
