part of 'core.dart';

class _AlienComputed<T> extends alien.ComputedNode<T> {
  _AlienComputed(this.parent, T Function(T? oldValue) getter)
    : super(
        flags: alien_system.ReactiveFlags.none,
        getter: getter,
      );

  final Computed<T> parent;

  void dispose() => alien.stop(this);

  @override
  bool didUpdate() {
    if ((flags & _hasChildEffect) != alien_system.ReactiveFlags.none) {
      alien.disposeChildDepsInReverse(this);
    }

    depsTail = null;
    flags =
        alien_system.ReactiveFlags.mutable |
        alien_system.ReactiveFlags.recursedCheck;
    final prevSub = alien.setActiveSub(this);
    try {
      ++alien.cycle;
      final oldValue = currentValue;
      currentValue = getter(oldValue);
      return !parent._compare(oldValue, currentValue);
    } finally {
      alien.setActiveSub(prevSub);
      flags &= ~alien_system.ReactiveFlags.recursedCheck;
      alien.purgeDeps(this);
    }
  }
}

class _AlienEffect extends alien.EffectNode<void> {
  _AlienEffect(this.parent, void Function() run, {bool? detach})
    : detach = detach ?? SolidartConfig.detachEffects,
      super(flags: alien_system.ReactiveFlags.watching, fn: run);

  final bool detach;
  final Effect parent;

  void run() => fn();

  void dispose() => alien.stopEffect(this);
}

class _AlienSignal<T> extends alien.SignalNode<Option<T>> {
  _AlienSignal(this.parent, Option<T> value)
    : super(
        flags: alien_system.ReactiveFlags.mutable,
        currentValue: value,
        pendingValue: value,
      );

  final SignalBase<dynamic> parent;

  bool forceDirty = false;

  @override
  bool didUpdate() {
    final previousValue = currentValue;
    currentValue = pendingValue;
    flags = alien_system.ReactiveFlags.mutable;

    if (forceDirty) {
      forceDirty = false;
      return true;
    }

    if (previousValue is None<T> || currentValue is None<T>) {
      return previousValue is! None<T> || currentValue is! None<T>;
    }

    if (!parent._compare(
      previousValue.safeUnwrap(),
      currentValue.safeUnwrap(),
    )) {
      return true;
    }

    return false;
  }
}
