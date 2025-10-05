// ignore_for_file: public_member_api_docs

part of '../signal.dart';

class SolidartSignal<T> extends alien.PresetWritableSignal<T?>
    with Disposable
    implements Signal<T> {
  SolidartSignal(T initialValue,
      {bool? autoDispose,
      bool Function(T?, T?)? comparator,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue})
      : this.internal(initialValue,
            autoDispose: autoDispose,
            comparator: comparator,
            name: name,
            equals: equals,
            trackInDevTools: trackInDevTools,
            trackPreviousValue: trackPreviousValue);

  SolidartSignal.internal(T? initialValue,
      {bool? autoDispose,
      bool Function(T?, T?)? comparator,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        comparator = comparator ?? identical,
        equals = equals ?? SolidartConfig.equals,
        name = name ?? nameFor('Signal'),
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue,
        super(initialValue: initialValue) {
    if (this.trackInDevTools) {
      notifySignalCreation();
    }
  }

  SolidartSignal.lazy(
      {bool? autoDispose,
      bool Function(T?, T?)? comparator,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue})
      : this.internal(null,
            autoDispose: autoDispose,
            comparator: comparator,
            name: name,
            equals: equals,
            trackInDevTools: trackInDevTools,
            trackPreviousValue: trackPreviousValue);

  @override
  final bool autoDispose;

  @override
  final bool Function(T?, T?) comparator;

  @override
  final bool equals;

  @override
  final String name;

  @override
  final bool trackInDevTools;

  @override
  final bool trackPreviousValue;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasPreviousValue => untrackedPreviousValue != null;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasValue => super.latestValue != null;

  @override
  T? untrackedPreviousValue;

  @override
  int get listenerCount {
    var count = 0;
    for (var link = subs; link != null; link = link.nextSub) {
      count++;
    }

    return count;
  }

  @override
  T get untrackedValue {
    if (null is! T && super.latestValue == null) {
      throw StateError(
          'Cannot get value of a $name that has not been initialized');
    }

    return super.latestValue as T;
  }

  @override
  T? get previousValue {
    if (trackPreviousValue && !isDisposed) {
      super();
    }

    return untrackedPreviousValue;
  }

  @override
  T get value {
    if (null is! T && super.latestValue == null) {
      throw StateError(
          'Cannot get value of a $name that has not been initialized');
    } else if (isDisposed) {
      return super.latestValue as T;
    }

    return super() as T;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  set value(T newValue) {
    if (isDisposed) return;
    super(newValue, true);
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get disposed => isDisposed;

  @override
  bool update() {
    if (isDisposed) return false;

    flags = 1 /* Mutable */;
    if ((equals && super.previousValue != latestValue) ||
        (!equals && !comparator(super.previousValue, latestValue))) {
      untrackedPreviousValue = super.previousValue;
      super.previousValue = latestValue;
      if (trackInDevTools) {
        notifySignalUpdate();
      }

      return true;
    }

    return false;
  }

  @override
  void dispose() {
    if (isDisposed) return;
    for (var link = subs; link != null; link = link.nextSub) {
      if (link.sub case final Disposable disposable) {
        disposable.maybeDispose();
      }
    }

    super.dispose();
    if (trackInDevTools) {
      notifySignalDisposal();
    }
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  ReadonlySignal<T> toReadonly() => ReadonlySignalProxy(this);

  @override
  String toString() => 'Signal<$T>(value: $untrackedValue)';
}
