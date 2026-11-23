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
    this.name,
    this.comparator = identical,
    bool? equals,
    bool? autoDispose,
    bool? trackInDevTools,
    bool? trackPreviousValue,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       equals = equals ?? SolidartConfig.equals,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue;

  String get _id;

  /// {@template SignalBase.name}
  /// The name of the signal, useful for logging purposes.
  /// {@endtemplate}
  final String? name;

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
  ///
  /// `observe()` and `addListener()` read it before [value]. A [Computed]
  /// runs its selector and a [Resource] resolves, like reading [value].
  bool get hasValue;

  /// Whether or not the signal has a value, without tracking.
  ///
  /// Unlike [hasValue], this never subscribes the running effect, never runs
  /// a [Computed]'s selector (a [Computed] always returns true) and never
  /// resolves a [Resource].
  ///
  /// A subclass or test double that overrides [value] should also override
  /// [hasValue] and [untrackedHasValue].
  bool get untrackedHasValue;

  /// Indicates if there is a previous value. It is especially
  /// helpful if [T] is nullable.
  bool get hasPreviousValue;

  /// Whether or not there is a previous value, without tracking.
  ///
  /// Unlike [hasPreviousValue], this never subscribes the running effect and
  /// never runs a [Computed]'s selector. It is false when
  /// [trackPreviousValue] is false.
  ///
  /// A subclass or test double that overrides [previousValue] should also
  /// override [hasPreviousValue] and [untrackedHasPreviousValue].
  bool get untrackedHasPreviousValue;

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  T? get previousValue;

  /// Returns the untracked previous value of the signal.
  T? get untrackedPreviousValue;

  /// Returns the untracked value of the signal.
  T get untrackedValue;

  /// Tells if the signal is disposed;
  bool get disposed;

  /// Fired when the signal is disposing
  void onDispose(VoidCallback cb);

  /// The total number of listeners subscribed to the signal.
  int get listenerCount;

  /// Tries to dispose the signal, if no observers are present
  void _mayDispose();

  /// Diposes the signal
  void dispose();

  /// Indicates if the [oldValue] and the [newValue] are equal
  bool _compare(T? oldValue, T? newValue);
}
