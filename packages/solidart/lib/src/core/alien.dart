part of 'core.dart';

class _AlienComputed<T> extends preset.ComputedNode<T> {
  _AlienComputed(this.parent, T Function(T? oldValue) getter)
    : super(flags: system.ReactiveFlags.none, getter: getter);

  final Computed<T> parent;

  void dispose() => preset.stop(this);
}

class _AlienEffect extends preset.EffectNode {
  _AlienEffect(
    this.parent,
    {required super.fn,
    bool? detach,
    required super.flags,
  }) : detach = detach ?? SolidartConfig.detachEffects;

  final bool detach;
  final Effect parent;

  void dispose() => preset.stop(this);
}

class _AlienSignal<T> extends preset.SignalNode<Option<T>> {
  _AlienSignal(this.parent, Option<T> value)
    : super(
        flags: system.ReactiveFlags.mutable,
        currentValue: value,
        pendingValue: value,
      );

  final SignalBase<dynamic> parent;
}
