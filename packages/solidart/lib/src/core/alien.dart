part of 'core.dart';

class _AlienComputed<T> extends alien_preset.ComputedNode<T> {
  _AlienComputed(this.parent, T Function(T? oldValue) getter)
    : super(flags: alien.ReactiveFlags.none, getter: getter);

  final Computed<T> parent;

  void dispose() => alien_preset.stop(this);
}

class _AlienEffect extends alien_preset.EffectNode {
  _AlienEffect(
    this.parent,
    {required super.fn,
    bool? detach,
    required super.flags,
  }) : detach = detach ?? SolidartConfig.detachEffects;

  final bool detach;
  final Effect parent;

  void dispose() => alien_preset.stop(this);
}

class _AlienSignal<T> extends alien_preset.SignalNode<Option<T>> {
  _AlienSignal(this.parent, Option<T> value)
    : super(
        flags: alien.ReactiveFlags.mutable,
        currentValue: value,
        pendingValue: value,
      );

  final SignalBase<dynamic> parent;
}
