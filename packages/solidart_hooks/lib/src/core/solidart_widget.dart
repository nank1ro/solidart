import 'package:flutter/widgets.dart';
import 'package:solidart/solidart.dart';

import '../_internal/active_element.dart';
import 'memoized.dart';

abstract class SolidartWidget extends StatelessWidget {
  const SolidartWidget({super.key});

  @override
  SolidartElement createElement() => SolidartElement(this);
}

class SolidartElement extends StatelessElement
    implements SolidartMemoizedElement {
  SolidartElement(SolidartWidget super.widget);

  @override
  late SolidartMemoized memoized = SolidartMemoized(
    value: Effect(scheduler, detach: true, autoDispose: false, autorun: false),
  );

  @override
  @mustCallSuper
  void unmount() {
    for (
      SolidartMemoized? node = memoized.head;
      node != null;
      node = node.next
    ) {
      final dispose = switch (node.value) {
        SignalBase signal => createSignalDisposer(signal),
        Effect effect => createEffectDisposer(effect),
        dynamic other => createOtherDisposer(other),
      };
      dispose?.call();
    }

    super.unmount();
  }

  @override
  Widget build() {
    final prevSub = reactiveSystem.activeSub;
    final prevElement = setCurrentElement(this);

    // ignore: invalid_use_of_protected_member
    final dep = reactiveSystem.activeSub = widgetEffect.subscriber;

    try {
      final built = super.build();
      // ignore: invalid_use_of_internal_member
      widgetEffect.setDependencies(dep);
      memoized = memoized.head;

      return built;
    } finally {
      reactiveSystem.activeSub = prevSub;
      setCurrentElement(prevElement);
    }
  }
}

extension on SolidartElement {
  Effect get widgetEffect => memoized.head.value as Effect;

  void scheduler() {
    if (dirty) return;
    markNeedsBuild();
  }

  VoidCallback? createSignalDisposer(SignalBase signal) {
    if (signal.autoDispose && !signal.disposed) {
      return signal.dispose;
    }

    return null;
  }

  VoidCallback? createEffectDisposer(Effect effect) {
    if (effect.autoDispose && !effect.disposed) {
      return effect.dispose;
    }

    return null;
  }

  VoidCallback? createOtherDisposer(dynamic other) {
    try {
      return other.dispose;
    } catch (_) {
      return null;
    }
  }
}
