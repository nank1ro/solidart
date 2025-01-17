part of 'core.dart';

class _AlienSignal<T> extends alien.Signal<T> {
  _AlienSignal(
    super.currentValue, {
    required this.parent,
  });

  final SignalBase<dynamic> parent;
}

class _AlienComputed<T> extends alien.Computed<T> {
  _AlienComputed(
    super.currentValue, {
    required this.parent,
  });

  final SignalBase<dynamic> parent;
}

class _AlienEffect<T> extends alien.Effect<T> {
  _AlienEffect(
    super.currentValue, {
    required this.parent,
  });

  final Effect parent;
}
