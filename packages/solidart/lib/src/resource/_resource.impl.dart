part of 'resource.dart';

class _ResourceImpl<T> implements Resource<T> {
  _ResourceImpl(
      {required this.lazy,
      required this.useRefreshing,
      required this.signal,
      this.fetcher,
      this.source,
      this.stream,
      this.debounceDelay}) {
    if (!lazy) refresh();
  }

  /// Indicates whether the resource should be computed lazily, defaults to true
  final bool lazy;

  /// Reactive signal values passed to the fetcher, optional.
  final ReadonlySignal<dynamic>? source;

  /// The asynchrounous function used to retrieve data.
  final FutureOr<T> Function()? fetcher;

  /// The stream used to retrieve data.
  final Stream<T> Function()? stream;

  /// The debounce delay when the source changes, optional.
  final Duration? debounceDelay;

  final bool useRefreshing;

  late final Signal<ResourceState<T>> signal;
  late final effect =
      Effect(debounceRefresh, detach: true, autorun: false, autoDispose: false)
          as alien.ReactiveNode;

  @override
  bool get autoDispose => signal.autoDispose;

  @override
  bool Function(ResourceState<T>?, ResourceState<T>?) get comparator =>
      signal.comparator;

  @override
  void dispose() {
    completer = null;

    subscription?.cancel().ignore();
    subscription = null;

    timer?.cancel();
    timer = null;

    signal.dispose();
    (effect as Effect).dispose();
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
  ResourceState<T> get state => value;

  @override
  bool get trackInDevTools => signal.trackInDevTools;

  @override
  bool get trackPreviousValue => signal.trackPreviousValue;

  @override
  ResourceState<T>? get untrackedPreviousValue => signal.untrackedPreviousValue;

  @override
  ResourceState<T> get untrackedValue => signal.untrackedValue;

  @override
  ResourceState<T> get value {
    if (lazy) refresh().ignore();
    return signal.value;
  }

  Timer? timer;
  void debounceRefresh() {
    if (debounceDelay == null) {
      return refresh().ignore();
    }

    timer?.cancel();
    timer = Timer(debounceDelay!, () {
      refresh().ignore();
      timer = null;
    });
  }

  @override
  Future<void> refresh() async {
    if (source != null) {
      final prevSub = alien.setActiveSub(effect);
      try {
        source!.value;
      } finally {
        alien.setActiveSub(prevSub);
      }
    }

    if (fetcher != null && stream == null) {
      return refetch();
    }
    return resubscribe();
  }

  @override
  FutureOr<T> untilReady() async {
    final state = await signal.until((e) => e.isReady);
    return state.asReady!.value;
  }

  @override
  ResourceState<T> update(
      ResourceState<T> Function(ResourceState<T> state) callback) {
    return signal.value = callback(signal.untrackedValue);
  }

  void transition() {
    if (useRefreshing) {
      signal.value = signal.untrackedValue.map(
        ready: (ready) => ready.copyWith(isRefreshing: true),
        error: (error) => error.copyWith(isRefreshing: true),
        loading: (_) => ResourceState<T>.loading(),
      );
    } else {
      signal.value = ResourceState<T>.loading();
    }
  }

  Completer<void>? completer;
  Future<void> refetch() async {
    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    }

    transition();
    completer = Completer<void>();
    final prevSub = alien.setActiveSub(null);
    try {
      final result = await fetcher!();
      signal.value = ResourceState<T>.ready(result);
      completer!.complete(null);
    } catch (error, stackTrace) {
      signal.value = ResourceState<T>.error(error, stackTrace: stackTrace);
      completer!.completeError(error, stackTrace);
    } finally {
      alien.setActiveSub(prevSub);
    }
  }

  StreamSubscription<T>? subscription;
  Future<void> resubscribe() async {
    transition();

    if (subscription != null) {
      subscription!.onData((data) {
        signal.value = ResourceState.ready(data);
      });
      subscription!.onError((Object error, StackTrace stackTrace) {
        signal.value = ResourceState.error(error, stackTrace: stackTrace);
      });
    }

    subscription ??= stream!().listen((state) {
      signal.value = ResourceState.ready(state);
    }, onError: (Object error, StackTrace stackTrace) {
      signal.value = ResourceState.error(error, stackTrace: stackTrace);
    });
  }

  @override
  ResourceState<T>? get previousState => previousValue;

  @override
  ResourceState<T>? get untrackedPreviousState => untrackedPreviousValue;

  @override
  ResourceState<T> get untrackedState => untrackedValue;
}
