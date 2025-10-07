/// A Dart library for Solidart Hooks, providing Flutter Hooks bindings for Solidart.
library;

export 'package:flutter_solidart/flutter_solidart.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Bind an existing signal to the hook widget
///
/// This will not dispose the signal when the widget is unmounted
T useExistingSignal<T extends ReadSignal>(T value) {
  final target = useMemoized(() => value, [value]);
  return use(_SignalHook('useExistingSignal', target, disposeOnUnmount: false));
}

/// {macro signal}
Signal<T> useSignal<T>(
  /// The initial value of the signal.
  T initialValue, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// {@macro SignalBase.comparator}
  bool Function(T? a, T? b) comparator = identical,

  /// {@macro SignalBase.trackPreviousValue}
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => Signal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      comparator: comparator,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(
    _SignalHook('useSignal', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// {macro list-signal}
ListSignal<T> useListSignal<T>(
  /// The initial value of the signal.
  Iterable<T> initialValue, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// {@macro SignalBase.comparator}
  bool Function(List<T>? a, List<T>? b) comparator = identical,

  /// {@macro SignalBase.trackPreviousValue}
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => ListSignal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      comparator: comparator,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(
    _SignalHook('useListSignal', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// {macro set-signal}
SetSignal<T> useSetSignal<T>(
  /// The initial value of the signal.
  Iterable<T> initialValue, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// {@macro SignalBase.comparator}
  bool Function(Set<T>? a, Set<T>? b) comparator = identical,

  /// {@macro SignalBase.trackPreviousValue}
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => SetSignal<T>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      comparator: comparator,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(
    _SignalHook('useSetSignal', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// {macro map-signal}
MapSignal<K, V> useMapSignal<K, V>(
  /// The initial value of the signal.
  Map<K, V> initialValue, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// {@macro SignalBase.comparator}
  bool Function(Map<K, V>? a, Map<K, V>? b) comparator = identical,

  /// {@macro SignalBase.trackPreviousValue}
  bool? trackPreviousValue,
}) {
  final target = useMemoized(
    () => MapSignal<K, V>(
      initialValue,
      autoDispose: autoDispose,
      name: name,
      equals: equals,
      trackInDevTools: trackInDevTools,
      comparator: comparator,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(
    _SignalHook('useMapSignal', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// Create a new computed signal
Computed<T> useComputed<T>(
  /// The selector function to compute the value.
  T Function() selector, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// {@macro SignalBase.comparator}
  bool Function(T? a, T? b) comparator = identical,

  /// {@macro SignalBase.trackPreviousValue}
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
      comparator: comparator,
      trackPreviousValue: trackPreviousValue,
    ),
    [],
  );
  return use(
    _SignalHook('useComputed', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// {macro resource}
Resource<T> useResource<T>(
  /// The asynchrounous function used to retrieve data.
  final Future<T> Function()? fetcher, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// Reactive signal values passed to the fetcher, optional.
  final SignalBase<dynamic>? source,

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
  return use(
    _SignalHook('useResource', target, disposeOnUnmount: autoDispose ?? true),
  );
}

/// {macro resource}
Resource<T> useResourceStream<T>(
  /// The asynchrounous function used to retrieve data.
  final Stream<T> Function()? stream, {

  /// {macro SignalBase.name}
  String? name,

  /// {macro SignalBase.equals}
  bool? equals,

  /// {@macro SignalBase.autoDispose}
  bool? autoDispose = false,

  /// {@macro SignalBase.trackInDevTools}
  bool? trackInDevTools,

  /// Reactive signal values passed to the fetcher, optional.
  final SignalBase<dynamic>? source,

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
  return use(
    _SignalHook(
      'useResourceStream',
      target,
      disposeOnUnmount: autoDispose ?? true,
    ),
  );
}

/// Create a signal effect
void useSolidartEffect(
  dynamic Function() cb, {

  void Function(Object error)? onError,

  /// The name of the effect, useful for logging
  String? name,

  /// Delay each effect reaction
  Duration? delay,

  /// Whether to automatically dispose the effect (defaults to true).
  ///
  /// This happens automatically when all the tracked dependencies are
  /// disposed.
  bool? autoDispose,

  /// Detach effect, default value is [SolidartConfig.detachEffects]
  bool? detach,

  /// Whether to automatically run the effect (defaults to true).
  bool? autorun,
}) {
  final instance = useRef(cb);
  instance.value = cb;
  useEffect(
    () => Effect(
      () => instance.value(),
      onError: onError,
      name: name,
      delay: delay,
      autoDispose: autoDispose,
      detach: detach,
      autorun: autorun,
    ).dispose,
    [],
  );
}

class _SignalHook<T, S extends ReadSignal<T>> extends Hook<S> {
  const _SignalHook(this.type, this.target, {this.disposeOnUnmount = true});

  final String type;
  final S target;
  final bool disposeOnUnmount;

  @override
  _SignalHookState<T, S> createState() => _SignalHookState();
}

class _SignalHookState<T, S extends ReadSignal<T>>
    extends HookState<S, _SignalHook<T, S>> {
  late DisposeEffect _cleanup;

  @override
  void initHook() {
    _listener();
    super.initHook();
  }

  @override
  void didUpdateHook(_SignalHook<T, S> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.target != oldHook.target) {
      _cleanup();
      _listener();
    }
  }

  void _listener() {
    // ignore: implicit_call_tearoffs
    _cleanup = Effect(() {
      hook.target.value;
      if (context.mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cleanup.call();
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
