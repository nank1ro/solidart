import 'dart:async';
import 'package:alien_signals/alien_signals.dart';

// ignore: public_member_api_docs
abstract interface class EffectOptions {
  // ignore: public_member_api_docs
  String get name;
  // ignore: public_member_api_docs
  Duration? get delay;
  // ignore: public_member_api_docs
  void Function(Object error)? get onError;
}

// ignore: public_member_api_docs
abstract interface class Effect implements EffectOptions {
  factory Effect(
    EffectRunner runner, {
    String name,
    Duration delay,
    void Function(Object error) onError,
  }) = _Effect;

  // ignore: public_member_api_docs
  bool get disposed;
  // ignore: public_member_api_docs
  void dispose();
  // ignore: public_member_api_docs
  void call();
}

// ignore: public_member_api_docs
typedef OnEffectDispose = void Function(void Function() cleanup);
// ignore: public_member_api_docs
typedef EffectRunner = void Function(OnEffectDispose onDispose);

final class _Effect
    implements Effect, EffectOptions, IEffect, Dependency<void> {
  _Effect(
    this.runner, {
    this.delay,
    this.name = 'Effect',
    this.onError,
  }) {
    if (activeTrackId != 0) {
      link(this, activeSub!);
    } else if (activeScopeTrackId != 0) {
      link(this, activeEffectScope!);
    }

    if (delay != null && delay! > Duration.zero) {
      var future = Future.delayed(delay!, run);
      if (onError != null) {
        future = future.catchError(onError!);
      }
      unawaited(future);
    } else {
      try {
        run();
      } catch (e) {
        onError?.call(e);
        dispose();
      }
    }
  }

  final EffectRunner runner;
  void Function()? cleanup;

  @override
  final Duration? delay;

  @override
  final String name;

  @override
  final void Function(Object error)? onError;

  @override
  bool disposed = false;

  @override
  void currentValue;

  @override
  Link? deps;

  @override
  Link? depsTail;

  @override
  SubscriberFlags flags = SubscriberFlags.dirty;

  @override
  int? lastTrackedId;

  @override
  Notifiable? nextNotify;

  @override
  Link? subs;

  @override
  Link? subsTail;

  @override
  void dispose() {
    if (disposed == true) return;
    disposed = true;

    startTrack(this);
    endTrack(this);

    if (cleanup != null) {
      final prevActiveTrackId = activeTrackId;
      final prevActiveScopeTrackId = activeScopeTrackId;

      activeTrackId = activeScopeTrackId = 0;
      try {
        cleanup!();
      } finally {
        activeTrackId = prevActiveTrackId;
        activeScopeTrackId = prevActiveScopeTrackId;
      }
    }
  }

  @override
  void call() => dispose();

  @override
  void notify() {
    if ((flags & SubscriberFlags.dirty) != 0) {
      run();
      return;
    }
    if ((flags & SubscriberFlags.toCheckDirty) != 0) {
      if (checkDirty(deps)) {
        run();
        return;
      } else {
        flags &= ~SubscriberFlags.toCheckDirty;
      }
    }
    if ((flags & SubscriberFlags.runInnerEffects) != 0) {
      flags &= ~SubscriberFlags.runInnerEffects;
      var link = deps;
      do {
        final dep = link!.dep;
        if (dep is Notifiable) {
          (dep! as Notifiable).notify();
        }

        link = link.nextDep;
      } while (link != null);
    }
  }

  void run() {
    final prevSub = activeSub;
    final prevTrackId = activeTrackId;
    setActiveSub(this, nextTrackId());
    startTrack(this);

    try {
      runner((fn) => cleanup = fn);
    } finally {
      setActiveSub(prevSub, prevTrackId);
      endTrack(this);
    }
  }
}
