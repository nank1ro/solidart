// ignore_for_file: public_member_api_docs

part of '../computed.dart';

class SolidartComputed<T> extends alien.PresetComputed<T>
    with Disposable
    implements Computed<T> {
  SolidartComputed(this.selector,
      {bool? autoDispose,
      this.comparator = identical,
      String? name,
      bool? equals,
      bool? trackInDevTools,
      bool? trackPreviousValue})
      : autoDispose = autoDispose ?? SolidartConfig.autoDispose,
        name = name ?? nameFor('Computed'),
        equals = equals ?? SolidartConfig.equals,
        trackInDevTools = trackInDevTools ?? SolidartConfig.devToolsEnabled,
        trackPreviousValue =
            trackPreviousValue ?? SolidartConfig.trackPreviousValue,
        super(getter: (_) => selector());

  /// The selector applied
  final T Function() selector;

  @override
  final bool autoDispose;

  @override
  final bool Function(T?, T?) comparator;

  @override
  final bool equals;

  @override
  // TODO: implement hasPreviousValue
  bool get hasPreviousValue => throw UnimplementedError();

  @override
  bool get hasValue => true;

  @override
  // TODO: implement listenerCount
  int get listenerCount => throw UnimplementedError();

  @override
  final String name;

  @override
  // TODO: implement previousValue
  T? get previousValue => throw UnimplementedError();

  @override
  final bool trackInDevTools;

  @override
  final bool trackPreviousValue;

  @override
  T? untrackedPreviousValue;

  @override
  T get untrackedValue => super.cachedValue as T;

  @override
  T get value => super();
}
