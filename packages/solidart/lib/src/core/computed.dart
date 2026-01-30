part of '../solidart.dart';

/// {@template solidart.computed}
/// # Computed
/// A computed signal derives its value from other signals. It is read-only
/// and recalculates whenever any dependency changes.
///
/// Use `Computed` to derive state or combine multiple signals:
/// ```dart
/// final firstName = Signal('Josh');
/// final lastName = Signal('Brown');
/// final fullName = Computed(() => '${firstName.value} ${lastName.value}');
/// ```
///
/// Computeds only notify when the derived value changes. You can customize
/// equality via [equals] to skip updates for equivalent values.
///
/// Like signals, computeds can track previous values once they have been read.
/// {@endtemplate}
class Computed<T> extends preset.ComputedNode<T>
    with DisposableMixin
    implements ReadonlySignal<T> {
  /// {@macro solidart.computed}
  Computed(
    ValueGetter<T> getter, {
    this.equals = identical,
    bool? autoDispose,
    String? name,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       identifier = ._(name),
       super(flags: system.ReactiveFlags.none, getter: (_) => getter()) {
    _notifySignalCreation(this);
  }

  @override
  final bool autoDispose;

  @override
  final Identifier identifier;

  @override
  final ValueComparator<T> equals;

  @override
  final bool trackPreviousValue;

  @override
  final bool trackInDevTools;

  Option<T> _previousValue = const None();

  @override
  T? get previousValue {
    if (!trackPreviousValue) return null;
    value;
    return _previousValue.safeUnwrap();
  }

  @override
  T? get untrackedPreviousValue {
    if (!trackPreviousValue) return null;
    return _previousValue.safeUnwrap();
  }

  @override
  T get untrackedValue {
    if (currentValue != null || null is T) {
      return currentValue as T;
    }
    return untracked(() => value);
  }

  @override
  T get value {
    assert(!isDisposed, 'Computed is disposed');
    return get();
  }

  @override
  T call() => value;

  @override
  bool didUpdate() {
    preset.cycle++;
    depsTail = null;
    flags = system.ReactiveFlags.mutable | system.ReactiveFlags.recursedCheck;

    final prevSub = preset.setActiveSub(this);
    try {
      final previousValue = currentValue;
      final pendingValue = getter(previousValue);
      if (equals(previousValue, pendingValue)) {
        return false;
      }

      if (trackPreviousValue && (previousValue is T)) {
        _previousValue = Some(previousValue);
      }

      currentValue = pendingValue;
      _notifySignalUpdate(this);
      return true;
    } finally {
      preset.activeSub = prevSub;
      flags &= ~system.ReactiveFlags.recursedCheck;
      preset.purgeDeps(this);
    }
  }

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkDeps(this);
    Disposable.unlinkSubs(this);
    preset.stop(this);
    super.dispose();
    _notifySignalDisposal(this);
  }
}
