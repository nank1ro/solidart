part of 'core.dart';

class _AlienComputed<T> extends alien.ComputedNode<T> {
  _AlienComputed(this.parent, T Function(T? oldValue) getter)
    : super(
        flags: alien_system.ReactiveFlags.none,
        getter: getter,
      );

  final Computed<T> parent;

  void dispose() {
    // `alien.stop` only unlinks the first subscriber, so unlink (and maybe
    // auto-dispose) all of them first — mirroring ReadableSignal.dispose — then
    // let `alien.stop` clear this node's deps and flags.
    unlinkSubscribers();
    alien.stop(this);
  }

  // Whether the getter runs from didUpdate(), not from the first get().
  bool updating = false;

  // The number of evaluations that changed the stored value or error.
  int changes = 0;

  @override
  bool didUpdate() => update().changed;

  // Evaluates once and returns the outcome of this call. An observer can run
  // the computed again while it is notified, so the outcome is read before
  // the notification, and a change stored by that nested run counts too.
  ({bool changed, SolidartCaughtException? error}) update() {
    final hadError = parent._hasError;
    final bool changed;
    updating = true;
    try {
      changed = super.didUpdate();
    } finally {
      updating = false;
    }
    final error = parent._error;
    if (error != null) {
      if (changed) changes++;
      return (changed: changed, error: error);
    }
    final result = hadError ? changed : !parent._equalsPrevious;
    if (result) changes++;
    final before = changes;
    // Committed: observers now read the new value, not the old error.
    parent._notifyEvaluated();
    return (changed: result || changes != before, error: null);
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
