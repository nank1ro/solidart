part of '../solidart.dart';

/// {@template solidart.resource}
/// # Resource
/// A resource is a signal designed for async data. It wraps the common states
/// of asynchronous work: `ready`, `loading`, and `error`.
///
/// Resources can be driven by:
/// - a `fetcher` that returns a `Future`
/// - a `stream` that yields values over time
/// - an optional `source` signal that triggers refreshes
///
/// Example using a fetcher:
/// ```dart
/// final userId = Signal(1);
///
/// Future<String> fetchUser() async {
///   final id = userId.value;
///   return 'user:$id';
/// }
///
/// final user = Resource(fetchUser, source: userId);
/// ```
///
/// The current state is available via [state] and provides helpers like
/// `when`, `maybeWhen`, `asReady`, `asError`, `isLoading`, and `isRefreshing`.
///
/// The [resolve] method starts the resource once. The [refresh] method forces
/// a new fetch or re-subscribes to the stream. When [useRefreshing] is true,
/// refresh updates the current state with `isRefreshing` instead of resetting
/// to `loading`.
/// {@endtemplate}
class Resource<T> extends Signal<ResourceState<T>> {
  /// {@macro solidart.resource}
  ///
  /// Creates a resource backed by a future-producing [fetcher].
  Resource(
    this.fetcher, {
    this.source,
    this.lazy = true,
    bool? useRefreshing,
    bool? trackPreviousState,
    this.debounceDelay,
    bool? autoDispose,
    String? name,
    bool? trackInDevTools,
    ValueComparator<ResourceState<T>> equals = identical,
  }) : stream = null,
       useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
       super(
         ResourceState<T>.loading(),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue:
             trackPreviousState ?? SolidartConfig.trackPreviousValue,
         trackInDevTools: trackInDevTools,
       ) {
    if (!lazy) {
      _resolveIfNeeded();
    }
  }

  /// {@macro solidart.resource}
  ///
  /// Creates a resource backed by a stream factory.
  ///
  /// Use this when your data source is an ongoing stream (e.g. sockets,
  /// Firestore snapshots, or SSE). The stream is subscribed on resolve and
  /// re-subscribed when [refresh] is called or when [source] changes.
  ///
  /// ```dart
  /// final ticks = Resource.stream(
  ///   () => Stream.periodic(const Duration(seconds: 1), (i) => i),
  ///   lazy: false,
  /// );
  /// ```
  ///
  /// When a refresh happens, the previous subscription is cancelled and
  /// events from older subscriptions are ignored.
  Resource.stream(
    this.stream, {
    this.source,
    this.lazy = true,
    bool? useRefreshing,
    bool? trackPreviousState,
    this.debounceDelay,
    bool? autoDispose,
    String? name,
    bool? trackInDevTools,
    ValueComparator<ResourceState<T>> equals = identical,
  }) : fetcher = null,
       useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
       super(
         ResourceState<T>.loading(),
         autoDispose: autoDispose,
         name: name,
         equals: equals,
         trackPreviousValue:
             trackPreviousState ?? SolidartConfig.trackPreviousValue,
         trackInDevTools: trackInDevTools,
       ) {
    if (!lazy) {
      _resolveIfNeeded();
    }
  }

  /// Optional source signal that triggers refreshes when it changes.
  ///
  /// When [source] updates, the resource refreshes. If [debounceDelay] is set,
  /// multiple source changes are coalesced.
  final ReadonlySignal<dynamic>? source;

  /// Fetches the resource value.
  final Future<T> Function()? fetcher;

  /// Provides a stream of resource values.
  final Stream<T> Function()? stream;

  /// Whether the resource is resolved lazily.
  ///
  /// When `true`, the resource resolves on first read or when [resolve] is
  /// called explicitly.
  final bool lazy;

  /// Whether to keep previous value while refreshing.
  ///
  /// When `true`, refresh updates the current state with `isRefreshing` rather
  /// than replacing it with `loading`.
  final bool useRefreshing;

  /// Optional debounce duration for source-triggered refreshes.
  final Duration? debounceDelay;

  bool _resolved = false;
  int _version = 0;
  Future<void>? _resolveFuture;
  Effect? _sourceEffect;
  StreamSubscription<T>? _streamSubscription;
  Timer? _debounceTimer;

  /// Returns the previous state (tracked read), or `null`.
  ///
  /// Previous state is available only after a tracked read.
  ResourceState<T>? get previousState {
    _resolveIfNeeded();
    if (!_resolved) return null;
    return previousValue;
  }

  /// Returns the current state, resolving lazily if needed.
  ResourceState<T> get state {
    _resolveIfNeeded();
    return value;
  }

  /// Sets the current state.
  set state(ResourceState<T> next) => value = next;

  /// Returns the previous state without tracking.
  ResourceState<T>? get untrackedPreviousState => untrackedPreviousValue;

  /// Returns the current state without tracking.
  ResourceState<T> get untrackedState => untrackedValue;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _sourceEffect?.dispose();
    _sourceEffect = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    super.dispose();
  }

  /// Re-fetches or re-subscribes to the resource.
  ///
  /// If the resource has not been resolved yet, this triggers [resolve]
  /// instead.
  Future<void> refresh() async {
    if (isDisposed) return;
    if (!_resolved) {
      await resolve();
      return;
    }

    if (fetcher != null) {
      return _refetch();
    }

    if (stream != null) {
      _resubscribe();
      return;
    }
  }

  /// Returns a future that completes with the value when the resource is ready.
  ///
  /// If the resource is already ready, it completes immediately.
  Future<T> untilReady() async {
    final state = await Future.value(until((value) => value.isReady));
    return state.asReady!.value;
  }

  /// Resolves the resource if it has not been resolved yet.
  ///
  /// Multiple calls are coalesced into a single in-flight resolve.
  Future<void> resolve() async {
    if (isDisposed) return;
    if (_resolveFuture != null) return _resolveFuture!;
    if (_resolved) return;

    _resolved = true;
    _resolveFuture = _doResolve().whenComplete(() {
      _resolveFuture = null;
    });

    return _resolveFuture!;
  }

  Future<void> _doResolve() async {
    if (fetcher != null) {
      await _fetch();
    }

    if (stream != null) {
      _subscribe();
    }

    if (source != null) {
      _setupSourceEffect();
    }
  }

  Future<void> _fetch() async {
    final requestId = ++_version;
    try {
      final result = await fetcher!();
      if (_isStale(requestId)) return;
      state = ResourceState<T>.ready(result);
    } catch (e, s) {
      if (_isStale(requestId)) return;
      state = ResourceState<T>.error(e, stackTrace: s);
    }
  }

  bool _isStale(int requestId) => requestId != _version || isDisposed;

  void _listenStream() {
    final requestId = ++_version;
    _streamSubscription = stream!().listen(
      (data) {
        if (_isStale(requestId)) return;
        state = ResourceState<T>.ready(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isStale(requestId)) return;
        state = ResourceState<T>.error(error, stackTrace: stackTrace);
      },
    );
  }

  Future<void> _refetch() async {
    _transition();
    return _fetch();
  }

  void _resolveIfNeeded() {
    if (!_resolved) {
      unawaited(resolve());
    }
  }

  void _resubscribe() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _transition();
    _listenStream();
  }

  void _setupSourceEffect() {
    var skipped = false;
    _sourceEffect = Effect(
      () {
        source!.value;
        if (!skipped) {
          skipped = true;
          return;
        }
        if (debounceDelay != null) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(debounceDelay!, () {
            if (isDisposed) return;
            untracked(refresh);
          });
        } else {
          untracked(refresh);
        }
      },
      autoDispose: false,
    );
  }

  void _subscribe() {
    _listenStream();
  }

  void _transition() {
    if (!useRefreshing) {
      state = ResourceState<T>.loading();
      return;
    }
    state.map(
      ready: (ready) {
        state = ready.copyWith(isRefreshing: true);
      },
      error: (error) {
        state = error.copyWith(isRefreshing: true);
      },
      loading: (_) {
        state = ResourceState<T>.loading();
      },
    );
  }
}
