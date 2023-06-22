// coverage:ignore-file

part of 'core.dart';

/// A callback that stops an observation when called
typedef DisposeObservation = void Function();

/// The base of a signal.
abstract class SignalBase<T> {
  /// The current signal value
  T get value;

  /// The current signal value
  T call();

  /// Indicates if there is a previous value. It is especially
  /// helpful if [T] is nullable.
  bool get hasPreviousValue;

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  T? get previousValue;

  /// Options used to customize the behaviour of a signal
  SignalOptions<T> get options;

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
