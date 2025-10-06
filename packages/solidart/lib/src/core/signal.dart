import 'package:alien_signals/preset_developer.dart' as alien;

import '_internal.dart';
import 'config.dart';
import 'debuggable.dart';
import 'disposable.dart';

abstract interface class ReadonlySignal<T> implements Disposable, Debuggable {
  factory ReadonlySignal(T initialValue,
      {bool? autoDispose, String? debugLabel}) = SolidartReadonlySignal<T>;

  T get value;
}

abstract interface class Signal<T> implements ReadonlySignal<T> {
  factory Signal(T initialValue, {bool? autoDispose, String? debugLabel}) =
      SolidartSignal<T>;

  factory Signal.lazy({bool? autoDispose, String? debugLabel}) =
      SolidartLazySignal<T>;

  set value(T newValue);

  ReadonlySignal<T> toReadonly();
}

class SolidartSignal<T> extends alien.PresetWritableSignal<T?>
    with AutoDisposable
    implements Signal<T> {
  SolidartSignal(T? initialValue, {bool? autoDispose, String? debugLabel})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        debugLabel = createDebugLabel<Signal<T>>(debugLabel),
        super(initialValue: initialValue);

  @override
  final bool autoDispose;

  @override
  final String debugLabel;

  @override
  bool disposed = false;

  @override
  T get value => super(null, false) as T;

  @override
  void set value(T newValue) => super(newValue, true);

  @override
  void dispose() {
    if (disposed) return;
    disposed = true;

    for (var link = subs; link != null; link = link.nextSub) {
      if (link.sub case final AutoDisposable disposable) {
        disposable.maybeDispose();
      }
    }
  }

  @override
  void maybeDispose() {
    if (subs == null) super.maybeDispose();
  }

  @override
  ReadonlySignal<T> toReadonly() => this;
}

class SolidartLazySignal<T> extends SolidartSignal<T> {
  SolidartLazySignal({super.autoDispose, super.debugLabel}) : super(null);

  bool isInitialized = false;

  @override
  T get value {
    if (!isInitialized) throw StateError('Signal not initialized');
    return super.value;
  }

  @override
  set value(T newValue) {
    if (!isInitialized) isInitialized = true;
    super.value = newValue;
  }
}

class SolidartReadonlySignal<T> extends SolidartSignal<T> {
  SolidartReadonlySignal(super.initialValue,
      {super.autoDispose, String? debugLabel})
      : super(debugLabel: createDebugLabel<ReadonlySignal<T>>(debugLabel));

  @override
  set value(_) {
    throw UnsupportedError(
        'Read-only signals do not allow new values to be written');
  }
}
