part of 'resource.dart';

class _ResourceImpl<T> with Disposable implements Resource<T> {
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

  /// Tracks whether initial refresh has started for lazy resources
  bool _hasStartedInitialRefresh = false;

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

  /// Cached current stream to avoid unnecessary resubscriptions
  Stream<T>? _currentStream;

  /// Cached broadcast stream mapped by original stream to allow re-subscription
  final Map<Stream<T>, Stream<T>> _broadcastStreamCache = {};

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
    internalDispose();
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
    if (lazy && !_hasStartedInitialRefresh) {
      _hasStartedInitialRefresh = true;
      refresh();
    }
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

    if (fetcher != null) {
      return refetch();
    }

    // For stream resources, either resubscribe (if source exists) or create initial subscription
    if (source != null) {
      resubscribe();
    } else if (subscription == null) {
      // Create initial subscription for sourceless stream resources
      resubscribe();
    }
  }

  @override
  FutureOr<T> untilReady() async {
    // Ensure lazy resource starts executing
    if (lazy && !_hasStartedInitialRefresh) {
      _hasStartedInitialRefresh = true;
      await refresh();
    }
    final state = await signal.until((e) => e.isReady);
    return state.asReady!.value;
  }

  @override
  ResourceState<T> update(
      ResourceState<T> Function(ResourceState<T> state) callback) {
    return signal.value = callback(signal.untrackedValue);
  }

  void transition() {
    final currentState = signal.untrackedValue;

    if (useRefreshing) {
      final newState = currentState.map(
        ready: (ready) => ready.copyWith(isRefreshing: true),
        error: (error) => error.copyWith(isRefreshing: true),
        loading: (_) => ResourceState<T>.loading(),
      );
      // Only update if the state actually changes
      if (newState != currentState) {
        signal.value = newState;
      }
    } else {
      // Only set to loading if not already loading
      if (!currentState.isLoading) {
        signal.value = ResourceState<T>.loading();
      }
    }
  }

  Completer<void>? completer;
  Future<void> refetch() async {
    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    }

    transition();
    completer = Completer<void>();
    try {
      final result = await fetcher!();
      signal.value = ResourceState<T>.ready(result);
      if (!completer!.isCompleted) {
        completer!.complete();
      }
    } catch (error, stackTrace) {
      signal.value = ResourceState<T>.error(error, stackTrace: stackTrace);
      if (!completer!.isCompleted) {
        completer!.complete();
      }
    }
  }

  StreamSubscription<T>? subscription;
  bool _resubscribing = false;

  void resubscribe() {
    if (_resubscribing) return;
    _resubscribing = true;

    try {
      transition();

      final newStream = stream!();

      // Only resubscribe if stream has changed or no existing subscription
      if (subscription == null || _currentStream != newStream) {
        // Cancel old subscription if it exists
        subscription?.cancel();

        // Create new subscription to the new stream immediately
        // Use cached broadcast stream for this specific stream
        _currentStream = newStream;

        // Get or create broadcast stream for this specific stream
        final broadcastStream = _broadcastStreamCache.putIfAbsent(
          newStream,
          () =>
              newStream.isBroadcast ? newStream : newStream.asBroadcastStream(),
        );

        subscription = broadcastStream.listen((state) {
          signal.value = ResourceState.ready(state);
        }, onError: (Object error, StackTrace stackTrace) {
          signal.value = ResourceState.error(error, stackTrace: stackTrace);
        });
      }
    } finally {
      _resubscribing = false;
    }
  }

  @override
  ResourceState<T>? get previousState => previousValue;

  @override
  ResourceState<T>? get untrackedPreviousState => untrackedPreviousValue;

  @override
  ResourceState<T> get untrackedState => untrackedValue;

  @override
  String toString() {
    return 'Resource<$T>(state: ${signal.value})';
  }
}
