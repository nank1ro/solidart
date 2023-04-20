// coverage:ignore-file

import 'package:meta/meta.dart';
import 'package:solidart/src/core/signal_options.dart';
import 'package:solidart/src/utils.dart';

/// The base of a signal.
abstract class SignalBase<T> {
  /// The current signal value
  @useResult
  T get value;

  /// The current signal value
  @useResult
  T call();

  /// The previous signal value
  ///
  /// Defaults to null when no previous value is present.
  @useResult
  T? get previousValue;

  /// Options used to customize the behaviour of a signal
  @useResult
  SignalOptions<T> get options;

  /// Tells if the signal is disposed;
  @useResult
  bool get disposed;

  /// Fired when the signal is disposing
  void onDispose(VoidCallback cb);

  /// The total number of listeners subscribed to the signal.
  @useResult
  int get listenerCount;

  /// Diposes the signal
  void dispose();
}
