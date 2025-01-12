// coverage:ignore-file

part of 'core.dart';

/// A callback that stops an observation when called
typedef DisposeObservation = void Function();

/// A custom comparator function
typedef ValueComparator<T> = bool Function(T a, T b);

/// The base of a signal.
abstract class SignalBase<T> {
  /// The base of a signal.
  SignalBase({
    required this.name,
    this.comparator = identical,
    bool? equals,
    bool? autoDispose,
    bool? trackInDevTools,
  })  : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        equals = equals ?? SolidartConfig.equals;

  /// {@template SignalBase.name}
  /// The name of the signal, useful for logging purposes.
  /// {@endtemplate}
  final String name;

  /// {@template SignalBase.equals}
  /// Whether to check the equality of the value with the == equality.
  ///
  /// Preventing signal updates if the new value is equal to the previous.
  ///
  /// When this value is true, the [comparator] is not used.
  /// {@endtemplate}
  final bool equals;

  /// {@template SignalBase.comparator}
  /// An optional comparator function, defaults to [identical].
  ///
  /// Preventing signal updates if the [comparator] returns true.
  ///
  /// Taken into account only if [equals] is false.
  /// {@endtemplate}
  final ValueComparator<T?>? comparator;

  /// {@template SignalBase.autoDispose}
  /// Whether to automatically dispose the signal (defaults to
  /// [SolidartConfig.autoDispose]).
  ///
  /// This happens automatically when there are no longer subscribers.
  /// If you set it to false, you should remember to dispose the signal manually
  /// {@endtemplate}
  final bool autoDispose;

  /// Whether to track the signal in the DevTools extension, defaults to
  /// [SolidartConfig.devToolsEnabled].
  final bool trackInDevTools;

  /// The current signal value
  T get value;

  /// Whether or not the signal has been initialized with a value.
  bool get hasValue;

  /// The current signal value
  T call();

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  MaybePreviousValue<T> get previousValue;

  /// Tells if the signal is disposed;
  bool get disposed;

  /// Fired when the signal is disposing
  void onDispose(VoidCallback cb);

  /// The total number of listeners subscribed to the signal.
  int get listenerCount;

  /// Observe the signal and trigger the [listener] every time the value changes
  DisposeObservation observe(
    ObserveCallback<T> listener, {
    bool fireImmediately = false,
  });

  /// Diposes the signal
  void dispose();
}
