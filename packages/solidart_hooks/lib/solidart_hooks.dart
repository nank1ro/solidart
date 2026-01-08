/// A Dart library for Solidart Hooks, providing Flutter Hooks bindings for Solidart.
library;

export 'package:flutter_solidart/flutter_solidart.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Bind an existing signal to the hook widget.
///
/// This will not dispose the signal when the widget is unmounted.
T useExistingSignal<T extends ReadonlySignal>(T value) {
  final target = useMemoized(() => value, [value]);
  return use(_SignalHook('useExistingSignal', target, disposeOnUnmount: false));
}

/// Create a [Signal] inside a hook widget.
Signal<T> useSignal<T>(
  /// The initial value of the signal.
  T initialValue, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the signal should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<T> equals = identical,

  /// Whether to track previous values.
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => Signal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(_SignalHook('useSignal', target));
}

/// Create a [ListSignal] inside a hook widget.
ListSignal<T> useListSignal<T>(
  /// The initial value of the signal.
  Iterable<T> initialValue, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the list signal should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<List<T>> equals = identical,

  /// Whether to track previous values.
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => ListSignal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(_SignalHook('useListSignal', target));
}

/// Create a [SetSignal] inside a hook widget.
SetSignal<T> useSetSignal<T>(
  /// The initial value of the signal.
  Iterable<T> initialValue, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the set signal should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<Set<T>> equals = identical,

  /// Whether to track previous values.
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => SetSignal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(_SignalHook('useSetSignal', target));
}

/// Create a [MapSignal] inside a hook widget.
MapSignal<K, V> useMapSignal<K, V>(
  /// The initial value of the signal.
  Map<K, V> initialValue, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the map signal should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<Map<K, V>> equals = identical,

  /// Whether to track previous values.
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => MapSignal<K, V>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(_SignalHook('useMapSignal', target));
}

/// Create a new computed signal
Computed<T> useComputed<T>(
  /// The selector function to compute the value.
  T Function() selector, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the computed should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<T> equals = identical,

  /// Whether to track previous values.
  bool? trackPreviousValue,
}) {
  final instance = useRef(selector);
  instance.value = selector;
  final target = useMemoized(
    () => Computed<T>(
      instance.value,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(_SignalHook('useComputed', target));
}

/// Create a [Resource] from a future-producing [fetcher].
Resource<T> useResource<T>(
  /// The asynchronous function used to retrieve data.
  final Future<T> Function()? fetcher, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the resource should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<ResourceState<T>> equals = identical,

  /// Reactive signal values passed to the fetcher, optional.
  final ReadonlySignal<dynamic>? source,

  /// Indicates whether the resource should be computed lazily, defaults to true
  final bool lazy = true,

  /// {@macro Resource.useRefreshing}
  bool? useRefreshing,

  /// Whether to track the previous state of the resource, defaults to true.
  bool? trackPreviousState,

  /// The debounce delay when the source changes, optional.
  final Duration? debounceDelay,
}) {
  final target = useMemoized(
    () => Resource<T>(
      fetcher,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      useRefreshing: useRefreshing,
      debounceDelay: debounceDelay,
      source: source,
      trackPreviousState: trackPreviousState,
      lazy: lazy,
    ),
    [],
  );
  return use(_SignalHook('useResource', target));
}

/// Create a [Resource] from a stream factory.
Resource<T> useResourceStream<T>(
  /// The asynchronous function used to retrieve data.
  final Stream<T> Function()? stream, {

  /// Optional name used by DevTools.
  String? name,

  /// Whether the resource should auto-dispose when unused.
  bool? autoDispose,

  /// Whether to report updates to DevTools.
  bool? trackInDevTools,

  /// Comparator used to skip equal updates.
  ValueComparator<ResourceState<T>> equals = identical,

  /// Reactive signal values passed to the fetcher, optional.
  final ReadonlySignal<dynamic>? source,

  /// Indicates whether the resource should be computed lazily, defaults to true
  final bool lazy = true,

  /// {@macro Resource.useRefreshing}
  bool? useRefreshing,

  /// Whether to track the previous state of the resource, defaults to true.
  bool? trackPreviousState,

  /// The debounce delay when the source changes, optional.
  final Duration? debounceDelay,
}) {
  final target = useMemoized(
    () => Resource<T>.stream(
      stream,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      useRefreshing: useRefreshing,
      debounceDelay: debounceDelay,
      source: source,
      trackPreviousState: trackPreviousState,
      lazy: lazy,
    ),
    [],
  );
  return use(_SignalHook('useResourceStream', target));
}

/// Create an effect inside a hook widget.
void useSolidartEffect(
  VoidCallback cb, {

  /// The name of the effect, useful for logging.
  String? name,

  /// Whether the effect should auto-dispose when unused.
  bool? autoDispose,

  /// Detach effect, default value is [SolidartConfig.detachEffects].
  bool? detach,
}) {
  final instance = useRef(cb);
  instance.value = cb;
  useEffect(
    () => Effect(
      () => instance.value(),
      name: name,
      autoDispose: autoDispose,
      detach: detach,
    ).dispose,
    [],
  );
}

class _SignalHook<T, S extends ReadonlySignal<T>> extends Hook<S> {
  const _SignalHook(this.type, this.target, {this.disposeOnUnmount = true});

  final String type;
  final S target;
  final bool disposeOnUnmount;

  @override
  _SignalHookState<T, S> createState() => _SignalHookState();
}

class _SignalHookState<T, S extends ReadonlySignal<T>>
    extends HookState<S, _SignalHook<T, S>> {
  @override
  void initHook() {
    super.initHook();
  }

  @override
  void dispose() {
    if (hook.disposeOnUnmount) {
      hook.target.dispose();
    }
  }

  @override
  S build(BuildContext context) => hook.target;

  @override
  Object? get debugValue => hook.target.value;

  @override
  String get debugLabel => '${hook.type}<$T>';
}
