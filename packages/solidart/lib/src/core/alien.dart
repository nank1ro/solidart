part of 'core.dart';

class _AlienComputed<T> extends alien.ReactiveNode implements _AlienUpdatable {
  _AlienComputed(this.parent, this.getter)
      : super(flags: 17 /* Mutable | Dirty */);

  final Computed<T> parent;
  final T Function(T? oldValue) getter;

  T? value;

  void dispose() => reactiveSystem.stopEffect(this);

  @override
  bool update() {
    final prevSub = reactiveSystem.setCurrentSub(this);
    reactiveSystem.startTracking(this);
    try {
      final oldValue = value;
      return oldValue != (value = getter(oldValue));
    } finally {
      reactiveSystem
        ..setCurrentSub(prevSub)
        ..endTracking(this);
    }
  }
}

class _AlienEffect extends alien.ReactiveNode {
  _AlienEffect(this.parent, this.run, {bool? detach})
      : detach = detach ?? SolidartConfig.detachEffects,
        super(flags: 2 /* Watching */);

  _AlienEffect? nextEffect;

  final bool detach;
  final Effect parent;
  final void Function() run;

  void dispose() => reactiveSystem.stopEffect(this);
}

class _AlienSignal<T> extends alien.ReactiveNode implements _AlienUpdatable {
  _AlienSignal(this.parent, this.value)
      : previousValue = value,
        super(flags: 1 /* Mutable */);

  final SignalBase<dynamic> parent;

  Option<T> previousValue;
  Option<T> value;

  bool forceDirty = false;

  @override
  bool update() {
    flags = 1 /* Mutable */;
    if (forceDirty) {
      forceDirty = false;
      return true;
    }
    if (!parent._compare(previousValue.safeUnwrap(), value.safeUnwrap())) {
      previousValue = value;
      return true;
    }

    return false;
  }
}

// ignore: one_member_abstracts
abstract interface class _AlienUpdatable {
  bool update();
}
