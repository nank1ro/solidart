import 'package:flutter/material.dart';
import 'package:solidart/src/core/signal_options.dart';

/// The base of a signal.
abstract class BaseSignal<T> extends Listenable {
  /// The current signal value
  T get value;

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

  /// The [select] function allows filtering unwanted rebuilds by reading only
  /// the properties that we care about.
  BaseSignal<Selected> select<Selected>(
    Selected Function(T value) selector,
  );

  void dispose();
}
