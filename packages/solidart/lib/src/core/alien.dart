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
    try {
      unlinkSubscribers();
    } finally {
      alien.stop(this);
    }
  }

  // Whether the getter runs from didUpdate(), not from the first get().
  bool updating = false;

  @override
  bool didUpdate() {
    final hadError = parent._hasError;
    final bool changed;
    updating = true;
    try {
      changed = super.didUpdate();
    } finally {
      updating = false;
    }
    if (parent._hasError) return changed;
    // A success replaces the recorded inputs, so the ones it no longer reads
    // are not retained.
    if (parent._deps.isNotEmpty) parent._recordInputs();
    // Read before notifying: an observer may evaluate the computed again.
    final result = hadError ? changed : !parent._equalsPrevious;
    // Committed: observers now read the new value, not the old error.
    parent._notifyEvaluated();
    return result;
  }
}

class _AlienEffect extends alien.EffectNode<void> {
  _AlienEffect(this.parent, void Function() run, {bool? detach})
    : detach = detach ?? SolidartConfig.detachEffects,
      super(flags: alien_system.ReactiveFlags.watching, fn: run) {
    cleanup = _cleanup;
  }

  final bool detach;
  final Effect parent;

  void run() => fn();

  // alien_signals runs the cleanup before each rerun, and when it stops the
  // effect, for example because its parent effect is disposed or reruns. Only
  // a stop clears the flags, and then the solidart effect is disposed too.
  // The stop runs inside a batch, a flush or a Computed evaluation. They
  // defer the auto-disposal of the dependencies, so this disposal does not
  // throw.
  void _cleanup() {
    if (flags == alien_system.ReactiveFlags.none) parent.dispose();
  }

  @override
  alien.EffectCleanup? runEffect() {
    // Set before fn runs, so the cleanup stays when fn throws.
    cleanup = _cleanup;
    fn();
    return _cleanup;
  }

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
