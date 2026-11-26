part of 'core.dart';

// A computed's saved reference to one of its inputs. Disposing the input
// clears [node]: alien_signals may have unlinked the computed from it already,
// and the saved reference must not keep a disposed input alive.
class _SavedInput {
  _SavedInput(this.node);

  alien_system.ReactiveNode? node;
}

class _AlienComputed<T> extends alien.ComputedNode<T> {
  _AlienComputed(this.parent, T Function(T? oldValue) getter)
    : super(
        flags: alien_system.ReactiveFlags.none,
        getter: getter,
      );

  final Computed<T> parent;

  late final saved = _SavedInput(this);

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

  // The number of evaluations that changed the stored value or error and
  // notified the observers. A run whose observer throws does not count, so
  // its change is not taken as delivered to the subscribers.
  int changes = 0;

  @override
  bool didUpdate() => update().changed;

  // Evaluates once and returns the outcome of this call. An observer can run
  // the computed again while it is notified, so the outcome is read before
  // the notification. A change stored by that nested run is a change for the
  // dirty check, but it already reached the subscribers, so [notify] is false.
  ({bool changed, bool notify, SolidartCaughtException? error}) update() {
    final hadError = parent._hasError;
    final bool changed;
    updating = true;
    try {
      changed = super.didUpdate();
    } finally {
      updating = false;
      // alien_signals restores the caller even if the selector disposed it.
      reactiveSystem._clearDisposedActiveEffect();
    }
    final error = parent._error;
    if (error != null) {
      if (changed) changes++;
      return (changed: changed, notify: changed, error: error);
    }
    // A success replaces the recorded inputs, so the ones it no longer reads
    // are not retained.
    if (parent._deps.isNotEmpty) parent._recordInputs();
    final result = hadError ? changed : !parent._equalsPrevious;
    final before = changes;
    // Committed: observers now read the new value, not the old error.
    parent._notifyEvaluated();
    final nested = changes != before;
    if (result) changes++;
    return (
      changed: result || nested,
      notify: result && !nested,
      error: null,
    );
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

  // A delayed effect can only have children after its first timer starts.
  // Keep them during the queued scheduling pass. The timer then calls
  // alien.run directly to stop them before running the callback again.
  static void runQueued(alien.EffectNode<dynamic> effect) {
    if ((effect.flags & _hasChildEffect) == alien_system.ReactiveFlags.none ||
        effect is! _AlienEffect ||
        effect.parent._timer == null) {
      return alien.run(effect);
    }
    effect.flags &= ~_hasChildEffect;
    try {
      alien.run(effect);
    } finally {
      // A stopped effect has no flags and no children.
      if (effect.flags != alien_system.ReactiveFlags.none) {
        effect.flags |= _hasChildEffect;
      }
    }
  }

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

  late final saved = _SavedInput(this);

  bool forceDirty = false;
  bool _readingDirtyValue = false;

  void forceNextUpdate() {
    forceDirty = true;
    flags =
        alien_system.ReactiveFlags.mutable | alien_system.ReactiveFlags.dirty;
    if (!_readingDirtyValue) currentValue = pendingValue;
  }

  @override
  Option<T> get() {
    if ((flags & alien_system.ReactiveFlags.dirty) ==
            alien_system.ReactiveFlags.none ||
        _readingDirtyValue) {
      return super.get();
    }

    // A comparator can force another update before this read captures the
    // committed value. Keep that value until the read has captured it.
    _readingDirtyValue = true;
    try {
      return super.get();
    } finally {
      _readingDirtyValue = false;
      if (forceDirty) currentValue = pendingValue;
    }
  }

  @override
  void set(Option<T> newValue) {
    // A pending forced update needs only the latest value outside a read.
    if (forceDirty && !_readingDirtyValue) currentValue = newValue;
    super.set(newValue);
  }

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
