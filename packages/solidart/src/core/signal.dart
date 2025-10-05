import 'package:alien_signals/preset_developer.dart' as alien;

import 'config.dart';
import 'disposable.dart';

abstract interface class ReadonlySignal<T> implements Disposable {
  T get value;
}

abstract interface class Signal<T> implements ReadonlySignal<T> {
  set value(T newValue);
}

class SolidartSignal<T> extends alien.PresetWritableSignal<T>
    with AutoDisposable
    implements Signal<T> {
  SolidartSignal(T initialValue, {bool? autoDispose})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        super(initialValue: initialValue);

  @override
  final bool autoDispose;

  @override
  bool disposed = false;

  @override
  T get value => super(null, false);

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
}
