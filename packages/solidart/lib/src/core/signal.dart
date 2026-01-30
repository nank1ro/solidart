part of '../solidart.dart';

/// {@template solidart.signal}
/// # Signals
/// Signals are the cornerstone of reactivity in v3. They store values that
/// change over time, and any reactive computation that reads a signal will
/// automatically update when the signal changes.
///
/// Create a signal with an initial value:
/// ```dart
/// final counter = Signal(0);
/// ```
///
/// Read the current value:
/// ```dart
/// counter.value; // 0
/// ```
///
/// Update the value:
/// ```dart
/// counter.value++;
/// // or
/// counter.value = 10;
/// ```
///
/// Signals support previous value tracking. When enabled, `previousValue`
/// updates only after the signal has been read at least once:
/// ```dart
/// final count = Signal(0);
/// count.value = 1;
/// count.previousValue; // null (not read yet)
/// count.value;         // establishes tracking
/// count.previousValue; // 0
/// ```
///
/// Signals can be created lazily using [Signal.lazy]. A lazy signal does not
/// have a value until it is first assigned, and reading it early throws
/// [StateError].
/// {@endtemplate}
/// {@template solidart.signal-equals}
/// Updates are skipped when [equals] reports the new value is equivalent to
/// the previous one.
/// {@endtemplate}
class Signal<T> extends preset.SignalNode<Option<T>>
    with DisposableMixin
    implements ReadonlySignal<T> {
  /// {@macro solidart.signal}
  ///
  /// {@macro solidart.signal-equals}
  Signal(
    T initialValue, {
    bool? autoDispose,
    String? name,
    ValueComparator<T> equals = identical,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : this._internal(
         Some(initialValue),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue: trackPreviousValue,
         trackInDevTools: trackInDevTools,
       );

  /// {@macro solidart.signal}
  ///
  /// This is a lazy signal: it has no value at construction time.
  /// Reading [value] before the first assignment throws [StateError].
  factory Signal.lazy({
    String? name,
    bool? autoDispose,
    ValueComparator<T> equals,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) = LazySignal;

  Signal._internal(
    Option<T> initialValue, {
    this.equals = identical,
    String? name,
    bool? autoDispose,
    bool? trackPreviousValue,
    bool? trackInDevTools,
  }) : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
       trackPreviousValue =
           trackPreviousValue ?? SolidartConfig.trackPreviousValue,
       trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
       identifier = ._(name),
       super(
         flags: system.ReactiveFlags.mutable,
         currentValue: initialValue,
         pendingValue: initialValue,
       ) {
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

  /// Whether the signal has been initialized.
  ///
  /// Regular signals are always initialized at construction time.
  bool get isInitialized => true;

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
  T get untrackedValue => super.currentValue.unwrap();

  @override
  T get value {
    assert(!isDisposed, 'Signal is disposed');
    return super.get().unwrap();
  }

  /// Sets the current value.
  ///
  /// {@macro solidart.signal-equals}
  set value(T newValue) {
    assert(!isDisposed, 'Signal is disposed');
    set(Some(newValue));
  }

  @override
  T call() => value;

  // TODO(nank1ro): See ReadonlySignal TODO, If `ReadonlySignal` rename
  // to `ReadSignal`, the `.toReadonly` method should be rename?
  @override
  bool didUpdate() {
    flags = system.ReactiveFlags.mutable;
    final current = currentValue;
    final pending = pendingValue;
    if (current is Some<T> &&
        pending is Some<T> &&
        equals(pending.value, current.value)) {
      return false;
    }

    if (trackPreviousValue && current is Some<T>) {
      _previousValue = current;
    }

    currentValue = pending;
    _notifySignalUpdate(this);
    return true;
  }

  @override
  void dispose() {
    if (isDisposed) return;
    Disposable.unlinkSubs(this);
    preset.stop(this);
    super.dispose();
    _notifySignalDisposal(this);
  }

  /// Returns a read-only view of this signal.
  ReadonlySignal<T> toReadonly() => this;
}
