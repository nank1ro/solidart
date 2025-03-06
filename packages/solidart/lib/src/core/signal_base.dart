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
    bool? trackPreviousValue,
  })  : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        equals = equals ?? SolidartConfig.equals,
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue;

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
  final ValueComparator<T?> comparator;

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

  /// Whether to track the previous value of the signal, defaults to true
  final bool trackPreviousValue;

  /// The current signal value
  T get value;

  /// The current signal value
  T call();

  /// Whether or not the signal has been initialized with a value.
  bool get hasValue;

  /// Indicates if there is a previous value. It is especially
  /// helpful if [T] is nullable.
  bool get hasPreviousValue;

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  T? get previousValue;

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

  /// Tries to dispose the signal, if no observers are present
  void _mayDispose();

  /// Diposes the signal
  void dispose();

  /// Indicates if the [oldValue] and the [newValue] are equal
  // ignore: unused_element
  bool _compare(T? oldValue, T? newValue);
}
