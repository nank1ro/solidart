part of 'resource.dart';

class _ResourceImpl<T> implements Resource<T> {
  _ResourceImpl(
      {this.fetcher,
      required this.lazy,
      this.source,
      this.stream,
      this.debounceDelay,
      required this.useRefreshing,
      required this.signal});

  /// Indicates whether the resource should be computed lazily, defaults to true
  final bool lazy;

  /// Reactive signal values passed to the fetcher, optional.
  final Signal<dynamic>? source;

  /// The asynchrounous function used to retrieve data.
  final Future<T> Function()? fetcher;

  /// The stream used to retrieve data.
  final Stream<T> Function()? stream;

  /// The debounce delay when the source changes, optional.
  final Duration? debounceDelay;

  final bool useRefreshing;

  late final Signal<ResourceState<T>> signal;

  @override
  bool get autoDispose => signal.autoDispose;

  @override
  bool Function(ResourceState<T>?, ResourceState<T>?) get comparator =>
      signal.comparator;

  @override
  void dispose() {
    signal.dispose();
  }

  @override
  bool get disposed => signal.disposed;

  @override
  bool get equals => signal.equals;

  @override
  bool get hasPreviousValue => signal.hasPreviousValue;

  @override
  bool get hasValue => signal.hasValue;

  @override
  int get listenerCount => signal.listenerCount;

  @override
  String get name => signal.name;

  @override
  void onDispose(void Function() callback) {
    signal.onDispose(callback);
  }

  @override
  ResourceState<T>? get previousValue => signal.previousValue;

  @override
  ResourceState<T> get state => signal.value;

  @override
  bool get trackInDevTools => signal.trackInDevTools;

  @override
  bool get trackPreviousValue => signal.trackPreviousValue;

  @override
  ResourceState<T>? get untrackedPreviousValue => signal.untrackedPreviousValue;

  @override
  ResourceState<T> get untrackedValue => signal.untrackedValue;

  @override
  ResourceState<T> get value => state;
}
