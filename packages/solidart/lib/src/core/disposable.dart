part of '../solidart.dart';

/// Disposable behavior for reactive primitives.
abstract class Disposable {
  /// Whether this instance has been disposed.
  bool get isDisposed;

  /// Disposes the instance.
  void dispose();

  /// Registers a callback to run on dispose.
  void onDispose(VoidCallback callback);

  /// Whether the node can be auto-disposed.
  static bool canAutoDispose(system.ReactiveNode node) => switch (node) {
    Disposable(:final isDisposed) && Configuration(:final autoDispose) =>
      !isDisposed && autoDispose,
    _ => false,
  };

  /// Unlinks dependencies from a node.
  ///
  /// This is used to break reactive links during disposal.
  static void unlinkDeps(system.ReactiveNode node) {
    var link = node.deps;
    while (link != null) {
      final next = link.nextDep;
      final dep = link.dep;
      final isLastSub =
          identical(dep.subs, link) &&
          link.prevSub == null &&
          link.nextSub == null;
      if (canAutoDispose(dep) && isLastSub) {
        (dep as Disposable).dispose();
      } else {
        preset.unlink(link, node);
        if (canAutoDispose(dep) && dep.subs == null) {
          (dep as Disposable).dispose();
        }
      }
      link = next;
    }
  }

  /// Unlinks subscribers from a node.
  ///
  /// This is used to break reactive links during disposal.
  static void unlinkSubs(system.ReactiveNode node) {
    var link = node.subs;
    while (link != null) {
      final next = link.nextSub;
      final sub = link.sub;
      preset.unlink(link, sub);
      if (canAutoDispose(sub) && sub.deps == null) {
        (sub as Disposable).dispose();
      }
      link = next;
    }
  }
}

/// Default [Disposable] implementation using cleanup callbacks.
mixin DisposableMixin implements Disposable {
  @internal
  /// Registered cleanup callbacks invoked on dispose.
  late final cleanups = <VoidCallback>[];

  @override
  bool isDisposed = false;

  @mustCallSuper
  @override
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    try {
      for (final callback in cleanups) {
        callback();
      }
    } finally {
      cleanups.clear();
    }
  }

  @mustCallSuper
  @override
  void onDispose(VoidCallback callback) {
    cleanups.add(callback);
  }
}
// coverage:ignore-end
