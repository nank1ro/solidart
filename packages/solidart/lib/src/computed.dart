import 'package:alien_signals/alien_signals.dart';
import 'package:solidart/src/devtools/_utils.dart';
import 'package:solidart/src/namespace.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
typedef ComputedGetter<T> = T Function();

// ignore: public_member_api_docs
abstract interface class Computed<T> implements ReadableSignal<T> {
  factory Computed(
    ComputedGetter<T> getter, {
    String name,
    bool Function(Object? a, Object? b) comparator,
    bool equals,
  }) = _Computed;
}

final class _Computed<T> extends SignalOptions
    implements Computed<T>, IComputed {
  _Computed(
    this.getter, {
    super.name = 'Computed',
    super.comparator,
    super.equals,
  }) {
    notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
    if (Solidart.dev && Solidart.observers.isNotEmpty) {
      for (final obs in Solidart.observers) {
        obs.didCreateSignal(this);
      }
    }
  }

  final ComputedGetter<T> getter;

  T? currentValue;

  @override
  Link? deps;

  @override
  Link? depsTail;

  @override
  SubscriberFlags flags = SubscriberFlags.dirty;

  @override
  int? lastTrackedId = 0;

  @override
  Link? subs;

  @override
  Link? subsTail;

  @override
  T get value {
    if ((flags & SubscriberFlags.dirty) != 0) {
      if (update() && subs != null) {
        shallowPropagate(subs);
      }
    } else if ((flags & SubscriberFlags.toCheckDirty) != 0) {
      if (checkDirty(deps)) {
        if (update() && subs != null) {
          shallowPropagate(subs);
        }
      } else {
        flags &= ~SubscriberFlags.toCheckDirty;
      }
    }
    if (activeTrackId != 0) {
      if (lastTrackedId != activeTrackId) {
        lastTrackedId = activeTrackId;
        link(this, activeSub!);
      }
    } else if (activeScopeTrackId != 0) {
      if (lastTrackedId != activeScopeTrackId) {
        lastTrackedId = activeScopeTrackId;
        link(this, activeEffectScope!);
      }
    }

    return currentValue!;
  }

  @override
  bool update() {
    final prevSub = activeSub;
    final prevTrackId = activeTrackId;
    setActiveSub(this, nextTrackId());
    startTrack(this);

    try {
      final oldValue = currentValue;
      currentValue = getter();
      return oldValue != currentValue;
    } finally {
      setActiveSub(prevSub, prevTrackId);
      endTrack(this);
      notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
      if (Solidart.dev && Solidart.observers.isNotEmpty) {
        for (final obs in Solidart.observers) {
          obs.didUpdateSignal(this);
        }
      }
    }
  }
}
