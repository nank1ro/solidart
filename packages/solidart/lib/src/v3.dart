// ignore_for_file: public_member_api_docs
// TODO(medz): Add code comments

import 'package:meta/meta.dart';
import 'package:solidart/deps/preset.dart' as preset;
import 'package:solidart/deps/system.dart' as system;

typedef ValueComparator<T> = bool Function(T? a, T? b);
typedef ValueGetter<T> = T Function();
typedef VoidCallback = ValueGetter<void>;

sealed class Option<T> {
  const Option();

  T unwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => throw StateError('Option is None'),
  };

  T? safeUnwrap() => switch (this) {
    Some<T>(:final value) => value,
    _ => null,
  };
}

final class Some<T> extends Option<T> {
  const Some(this.value);

  final T value;
}

final class None<T> extends Option<T> {
  const None();
}

final class SolidartConfig {
  const SolidartConfig._();

  static bool autoDispose = false;
  static bool detachEffects = false;
}

class Identifier {
  Identifier._(this.name) : value = _counter++;
  static int _counter = 0;

  final String? name;
  final int value;
}

abstract interface class Configuration {
  Identifier get identifier;
  bool get autoDispose;
}

abstract class Disposable {
  bool get isDisposed;

  void onDispose(VoidCallback callback);
  void dispose();

  static bool canAutoDispose(system.ReactiveNode node) => switch (node) {
    Disposable(:final isDisposed) && Configuration(:final autoDispose) =>
      !isDisposed && autoDispose,
    _ => false,
  };

  static void unlinkDeps(system.ReactiveNode node) {
    var link = node.deps;
    while (link != null) {
      final next = link.nextDep;
      final dep = link.dep;
      preset.unlink(link, node);
      if (canAutoDispose(dep) && dep.subs == null) {
        (dep as Disposable).dispose();
      }
      link = next;
    }
  }

  static void unlinkSubs(system.ReactiveNode node) {
    var link = node.subs;
    while (link != null) {
      final next = link.nextSub;
      final sub = link.sub;
      preset.unlink(link, sub);
      if (canAutoDispose(sub) && sub.deps == null) {
        (sub as Disposable).dispose();
      }
      link = next;
    }
  }
}

abstract interface class SignalConfiguration<T> implements Configuration {
  ValueComparator<T> get equals;
}

// TODO(nank1ro): Maybe rename to `ReadSignal`? medz: I still recommend `ReadonlySignal` because it is semantically clearer., https://github.com/nank1ro/solidart/pull/166#issuecomment-3623175977
abstract interface class ReadonlySignal<T>
    implements system.ReactiveNode, Disposable, SignalConfiguration<T> {
  T get value;
  T get untrackedValue;
}

class Signal<T> extends preset.SignalNode<Option<T>>
    with DisposableMixin
    implements ReadonlySignal<T> {
  Signal(
    T initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<T> equals = identical,
  }) : this._internal(
         Some(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
       );

  Signal._internal(
    Option<T> initialValue, {
    this.equals = identical,
    String? name,
    bool? autoDispose,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       identifier = Identifier._(name),
       super(
         flags: system.ReactiveFlags.mutable,
         currentValue: initialValue,
         pendingValue: initialValue,
       );

  factory Signal.lazy({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals,
  }) = LazySignal;

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  @override
  final ValueComparator<T> equals;

  @override
  T get value {
    assert(!isDisposed, 'Signal is disposed');
    return super.get().unwrap();
  }

  set value(T newValue) {
    assert(!isDisposed, 'Signal is disposed');
    set(Some(newValue));
  }

  @override
  T get untrackedValue => super.currentValue.unwrap();

  // TODO(nank1ro): See ReadonlySignal TODO, If `ReadonlySignal` rename
  // to `ReadSignal`, the `.toReadonly` method should be rename?
  ReadonlySignal<T> toReadonly() => this;

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkSubs(this);
    preset.stop(this);
    super.dispose();
  }

  @override
  bool didUpdate() {
    flags = system.ReactiveFlags.mutable;
    if (equals(pendingValue.unwrap(), currentValue.unwrap())) {
      return false;
    }

    currentValue = pendingValue;
    return true;
  }
}

class LazySignal<T> extends Signal<T> {
  LazySignal({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals = identical,
  }) : super._internal(
         const None(),
         name: name,
         autoDispose: autoDispose,
         equals: equals,
       );

  bool get isInitialized => currentValue is Some<T>;

  @override
  T get value {
    if (isInitialized) return super.value;
    throw StateError(
      'LazySignal is not initialized, Please call `.value = <newValue>` first.',
    );
  }

  @override
  bool didUpdate() {
    if (!isInitialized) {
      flags = system.ReactiveFlags.mutable;
      currentValue = pendingValue;
      return true;
    }

    return super.didUpdate();
  }
}

class Computed<T> extends preset.ComputedNode<T>
    with DisposableMixin
    implements ReadonlySignal<T> {
  Computed(
    ValueGetter<T> getter, {
    this.equals = identical,
    bool? autoDispose,
    String? name,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       identifier = Identifier._(name),
       super(flags: system.ReactiveFlags.none, getter: (_) => getter());

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  @override
  final ValueComparator<T> equals;

  @override
  T get value {
    assert(!isDisposed, 'Computed is disposed');
    return get();
  }

  @override
  T get untrackedValue {
    if (currentValue != null || null is T) {
      return currentValue as T;
    }

    final prevSub = preset.setActiveSub();
    try {
      return value;
    } finally {
      preset.activeSub = prevSub;
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkSubs(this);
    Disposable.unlinkDeps(this);
    preset.stop(this);
    super.dispose();
  }

  @override
  bool didUpdate() {
    preset.cycle++;
    depsTail = null;
    flags = system.ReactiveFlags.mutable | system.ReactiveFlags.recursedCheck;

    final prevSub = preset.setActiveSub(this);
    try {
      final pendingValue = getter(currentValue);
      if (equals(currentValue, pendingValue)) {
        return false;
      }

      currentValue = pendingValue;
      return true;
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
      preset.purgeDeps(this);
    }
  }
}

class Effect extends preset.EffectNode
    with DisposableMixin
    implements Disposable, Configuration {
  Effect(
    VoidCallback callback, {
    bool? autoDispose,
    String? name,
    bool? detach,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       identifier = Identifier._(name),
       detach = detach ?? SolidartConfig.detachEffects,
       super(
         fn: callback,
         flags:
             system.ReactiveFlags.watching | system.ReactiveFlags.recursedCheck,
       ) {
    final prevSub = preset.setActiveSub(this);
    if (prevSub != null && !this.detach) {
      preset.link(this, prevSub, 0);
    }

    try {
      callback();
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
    }
  }

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  final bool detach;

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkDeps(this);
    preset.stop(this);
    super.dispose();
  }
}

mixin DisposableMixin implements Disposable {
  @internal
  late final cleanups = <VoidCallback>[];

  @override
  bool isDisposed = false;

  @mustCallSuper
  @override
  void onDispose(VoidCallback callback) {
    cleanups.add(callback);
  }

  @mustCallSuper
  @override
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    try {
      for (final callback in cleanups) {
        callback();
      }
    } finally {
      cleanups.clear();
    }
  }
}
