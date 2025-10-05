import '_internal.dart';
import 'config.dart';
import 'disposable.dart';
import 'signal.dart';

import 'package:alien_signals/preset_developer.dart' as alien;

abstract interface class Computed<T> implements ReadonlySignal<T> {}

class SolidartComputed<T> extends alien.PresetComputed<T>
    with AutoDisposable
    implements Computed<T> {
  static T Function(T?) toAlienGetter<T>(T Function() callback) {
    return (_) => callback();
  }

  SolidartComputed(T Function() callback,
      {bool? autoDispose, String? debugLabel})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        debugLabel = createDebugLabel(debugLabel),
        super(getter: toAlienGetter<T>(callback));

  late final dependencies = <AutoDisposable>[];

  @override
  final String debugLabel;

  @override
  final bool autoDispose;

  @override
  bool disposed = false;

  @override
  T get value {
    final value = super();
    dependencies.length = 0;
    for (var link = this.deps; link != null; link = link.nextDep) {
      if (link.dep case final AutoDisposable disposable) {
        dependencies.add(disposable);
      }
    }

    return value;
  }

  @override
  void dispose() {
    if (disposed) return;

    disposed = true;
    for (var link = subs; link != null; link = link.nextSub) {
      if (link.sub case final AutoDisposable disposable) {
        disposable.maybeDispose();
      }
    }

    alien.system.unwatched(this);
    dependencies.forEach((child) => child.maybeDispose());
  }

  @override
  void maybeDispose() {
    if (subs == null) super.maybeDispose();
  }
}
