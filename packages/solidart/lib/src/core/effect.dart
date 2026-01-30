part of '../solidart.dart';

/// {@template solidart.effect}
/// # Effect
/// Effects run a side-effect whenever any signal they read changes.
///
/// ```dart
/// final counter = Signal(0);
/// Effect(() {
///   print('count: ${counter.value}');
/// });
/// ```
///
/// Effects run once immediately when created. If you need a lazy effect,
/// create it with [Effect.manual] and call [run] yourself.
///
/// Nested effects can either attach to their parent (default) or detach by
/// passing `detach: true` or by enabling [SolidartConfig.detachEffects].
///
/// Call [dispose] to stop the effect and release dependencies.
/// {@endtemplate}
class Effect extends preset.EffectNode
    with DisposableMixin
    implements Disposable, Configuration {
  /// {@macro solidart.effect}
  factory Effect(
    VoidCallback callback, {
    bool? autoDispose,
    String? name,
    bool? detach,
  }) => .manual(
    callback,
    autoDispose: autoDispose,
    name: name,
    detach: detach,
  )..run();

  /// Creates an effect without running it.
  ///
  /// Use this when you need to *delay* the first run or decide *when* the
  /// effect should start tracking dependencies. Common cases:
  /// - you must create several signals first and only then start the effect
  /// - you want to control the first run in tests
  /// - you need conditional startup (e.g. after async setup)
  ///
  /// The effect will not track anything until you call [run]:
  /// ```dart
  /// final count = Signal(0);
  /// final effect = Effect.manual(() {
  ///   print('count: ${count.value}');
  /// });
  ///
  /// count.value = 1; // no output yet
  /// effect.run();    // prints "count: 1" and starts tracking
  /// ```
  ///
  /// If you want the effect to run immediately, use the [Effect] factory.
  Effect.manual(
    VoidCallback callback, {
    bool? autoDispose,
    String? name,
    bool? detach,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       identifier = ._(name),
       detach = detach ?? SolidartConfig.detachEffects,
       super(
         fn: callback,
         flags:
             system.ReactiveFlags.watching | system.ReactiveFlags.recursedCheck,
       );

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  /// Whether this effect detaches from parent subscriptions.
  final bool detach;

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkDeps(this);
    preset.stop(this);
    super.dispose();
  }

  /// Runs the effect and tracks dependencies.
  void run() {
    final prevSub = preset.setActiveSub(this);
    if (!detach && prevSub != null) {
      preset.link(this, prevSub, 0);
    }

    try {
      fn();
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
    }
  }
}
