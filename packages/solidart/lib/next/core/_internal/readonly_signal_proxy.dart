// ignore_for_file: public_member_api_docs

import 'package:solidart/next/core/signal.dart';

final class ReadonlySignalProxy<T> implements ReadonlySignal<T> {
  const ReadonlySignalProxy(this.upstream);

  final ReadonlySignal<T> upstream;

  @override
  bool get autoDispose => upstream.autoDispose;

  @override
  bool Function(T? p1, T? p2) get comparator => upstream.comparator;

  @override
  void dispose() => upstream.dispose();

  @override
  bool get equals => upstream.equals;

  @override
  bool get hasPreviousValue => upstream.hasPreviousValue;

  @override
  bool get hasValue => upstream.hasValue;

  @override
  int get listenerCount => upstream.listenerCount;

  @override
  String get name => upstream.name;

  @override
  void onDispose(void Function() callback) => upstream.onDispose(callback);

  @override
  T? get previousValue => upstream.previousValue;

  @override
  bool get trackInDevTools => upstream.trackInDevTools;

  @override
  bool get trackPreviousValue => upstream.trackPreviousValue;

  @override
  T? get untrackedPreviousValue => upstream.untrackedPreviousValue;

  @override
  T get untrackedValue => upstream.untrackedValue;

  @override
  T get value => upstream.value;
}
