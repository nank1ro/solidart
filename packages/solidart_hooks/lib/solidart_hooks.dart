/// A Dart library for Solidart Hooks, providing Flutter Hooks bindings for Solidart.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart/solidart.dart';

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
    () => Signal(
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
  return;
}

class _SignalHook<T, S extends ReadSignal<T>> extends Hook<S> {
  const _SignalHook(
    this.type,
    this.initialData, {
    this.disposeOnUnmount = true,
  });

  final String type;
  final S initialData;
  final bool disposeOnUnmount;

  @override
  _SignalHookState<T, S> createState() => _SignalHookState();
}

class _SignalHookState<T, S extends ReadSignal<T>>
    extends HookState<S, _SignalHook<T, S>> {
  late final _instance = hook.initialData;
  late Effect _cleanup;

  @override
  void initHook() {
    // ignore: implicit_call_tearoffs
    _cleanup = Effect(() {
      _instance.value;
      if (context.mounted) setState(() {});
    });
    super.initHook();
  }

  @override
  void dispose() {
    _cleanup.call();
    if (hook.disposeOnUnmount) {
      _instance.dispose();
    }
  }

  @override
  S build(BuildContext context) => _instance;

  @override
  Object? get debugValue => _instance.value;

  @override
  String get debugLabel => '${hook.type}<$T>';
}
