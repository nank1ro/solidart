// ignore_for_file: public_member_api_docs

import 'package:solidart/deps/preset.dart' as preset;
import 'package:solidart/deps/system.dart' as system;

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

/// Maybe rename to `ReadSignal` ?
/// CC @nank1ro
abstract interface class ReadonlySignal<T> implements system.ReactiveNode {
  T get value;
}

class Signal<T> extends preset.SignalNode<Option<T>>
    implements ReadonlySignal<T> {
  Signal(T initialValue)
    : super(
        flags: system.ReactiveFlags.mutable,
        currentValue: Some(initialValue),
        pendingValue: const None(),
      ) {
    pendingValue = currentValue;
  }

  Signal._internal(Option<T> initialValue)
    : super(
        flags: system.ReactiveFlags.mutable,
        currentValue: initialValue,
        pendingValue: initialValue,
      );

  factory Signal.lazy() = LazySignal;

  @override
  T get value => super.get().unwrap();

  set value(T newValue) => set(Some(newValue));
}

class LazySignal<T> extends Signal<T> {
  LazySignal() : super._internal(const None());

  @override
  T get value {
    if (currentValue is None) {
      throw StateError(
        'LazySignal is not initialized, Please call `.value` first.',
      );
    }

    return super.value;
  }
}

class Computed<T> extends preset.ComputedNode<T> implements ReadonlySignal<T> {
  Computed(ValueGetter<T> getter)
    : super(flags: system.ReactiveFlags.none, getter: (_) => getter());

  @override
  T get value => super.get();
}

class Effect extends preset.EffectNode {
  Effect(VoidCallback callback)
    : super(
        fn: callback,
        flags:
            system.ReactiveFlags.watching | system.ReactiveFlags.recursedCheck,
      ) {
    final prevSub = preset.setActiveSub(this);
    if (prevSub != null) preset.link(this, prevSub, 0);
    try {
      callback();
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
    }
  }
}
