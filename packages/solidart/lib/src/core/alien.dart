part of 'core.dart';

abstract interface class _Effect implements alien.Dependency, alien.Subscriber {
  void Function() get fn;
}

abstract interface class _Signal<T> implements alien.Dependency {
  abstract T currentValue;
  T call();
}

abstract interface class _WriteableSignal<T> extends _Signal<T> {
  @override
  T call([T value]);
}

abstract interface class _Computed<T> extends _Signal<T?>
    implements alien.Subscriber {
  @override
  abstract T? currentValue;

  @override
  T call();

  bool notify();
}

class _AlienSignal<T> with alien.Dependency implements _WriteableSignal<T> {
  _AlienSignal(
    this.currentValue, {
    required this.parent,
  });

  @override
  T currentValue;

  final SignalBase<dynamic> parent;

  @override
  T call([T? _]) {
    if (reactiveSystem.activeSub != null) {
      reactiveSystem.link(this, reactiveSystem.activeSub!);
    }

    return currentValue;
  }
}

class _AlienComputed<T>
    with alien.Dependency, alien.Subscriber
    implements _Computed<T> {
  _AlienComputed(this.getter, {required this.parent});

  final T Function(T? oldValue) getter;

  final Computed<T> parent;

  @override
  T? currentValue;

  @override
  int flags = alien.SubscriberFlags.computed | alien.SubscriberFlags.dirty;

  @override
  T call() {
    if ((flags &
            (alien.SubscriberFlags.dirty |
                alien.SubscriberFlags.pendingComputed)) !=
        0) {
      reactiveSystem.processComputedUpdate(this, flags);
    }
    if (reactiveSystem.activeSub != null) {
      reactiveSystem.link(this, reactiveSystem.activeSub!);
    } else if (reactiveSystem.activeScope != null) {
      reactiveSystem.link(this, reactiveSystem.activeScope!);
    }

    return currentValue as T;
  }

  @override
  bool notify() {
    final oldValue = currentValue;
    final newValue = getter(oldValue);
    if (oldValue != newValue) {
      currentValue = newValue;
      return true;
    }
    return false;
  }

  void dispose() {
    reactiveSystem.disposeSub(this);
  }
}

class _AlienEffect with alien.Dependency, alien.Subscriber implements _Effect {
  _AlienEffect(
    this.fn, {
    required this.parent,
  });

  @override
  final void Function() fn;

  final Effect parent;

  @override
  int flags = alien.SubscriberFlags.effect;

  void dispose() {
    reactiveSystem.disposeSub(this);
  }

  void run() {
    if (reactiveSystem.activeSub != null) {
      reactiveSystem.link(this, reactiveSystem.activeSub!);
    } else if (reactiveSystem.activeScope != null) {
      reactiveSystem.link(this, reactiveSystem.activeScope!);
    }
    reactiveSystem.runEffect(this);
    return;
  }
}
