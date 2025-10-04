// ignore_for_file: public_member_api_docs

part of '../computed.dart';

class SolidartComputed<T> extends alien.PresetComputed<T>
    with Disposable
    implements Computed<T> {
  SolidartComputed(this.selector,
      {bool? autoDispose,
      bool Function(T?, T?)? comparator,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        comparator = comparator ?? identical,
        name = name ?? nameFor('Computed'),
        equals = equals ?? SolidartConfig.equals,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue,
        super(getter: (_) => selector()) {
    notifySignalCreation();
  }

  /// The selector applied
  final T Function() selector;

  @override
  final bool trackInDevTools;

  @override
  final bool trackPreviousValue;

  @override
  final String name;

  @override
  T? untrackedPreviousValue;

  @override
  final bool autoDispose;

  @override
  final bool Function(T?, T?) comparator;

  @override
  final bool equals;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasPreviousValue => untrackedPreviousValue != null && flags != 0;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get hasValue => true;

  @override
  int get listenerCount {
    var count = 0;
    for (var link = subs; link != null; link = link.nextSub) {
      count++;
    }

    return count;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  T? get previousValue {
    if (trackPreviousValue) super();
    return untrackedPreviousValue;
  }

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  T get untrackedValue => cachedValue as T;

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  T get value => super();

  @override
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get disposed => isDisposed;

  @override
  bool update() {
    if (isDisposed) return false;

    final oldValue = cachedValue;
    final result = super.update();
    final newValue = cachedValue;
    if (equals) {
      if (result) {
        untrackedPreviousValue = oldValue;
        notifySignalUpdate();
      }
      return result;
    } else if (comparator(oldValue, newValue)) {
      return false;
    }

    untrackedPreviousValue = oldValue;
    notifySignalUpdate();

    return true;
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
  }
}
