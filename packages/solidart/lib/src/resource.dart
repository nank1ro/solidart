import 'dart:async';

import 'package:meta/meta.dart';
import 'package:solidart/src/_internal/name_for.dart';
import 'package:solidart/src/config.dart';
import 'package:solidart/src/signal.dart';
import 'package:solidart/src/until.dart';

/// {@template resource}
/// `Resources` are special `Signal`s designed specifically to handle Async
/// loading. Their purpose is wrap async values in a way that makes them easy
/// to interact with handling the common states of a future __data__, __error__
/// and __loading__.
///
/// Resources can be driven by a `source` signal that provides the query to an
/// async data `fetcher` function that returns a `Future` or to a `stream` that
/// is listened again when the source changes.
///
/// The contents of the `fetcher` function can be anything. You can hit typical
/// REST endpoints or GraphQL or anything that generates a future. Resources
/// are not opinionated on the means of loading the data, only that they are
/// driven by an async operation.
///
/// Let's create a Resource:
///
/// ```dart
/// // Using http as a client
/// import 'package:http/http.dart' as http;
///
/// // The source
/// final userId = Signal(1);
///
/// // The fetcher
/// Future<String> fetchUser() async {
///   final response = await http.get(
///     Uri.parse('https://jsonplaceholder.typicode.com/users/${userId.value}/'),
///     headers: {'Accept': 'application/json'},
///   );
///   return response.body;
/// }
///
/// // The resource (source is optional)
/// final user = Resource(fetchUser, source: userId);
/// ```
///
/// A Resource can also be driven from a [stream] instead of a Future.
/// In this case you just need to pass the `stream` field to the
/// `Resource.stream` constructor.
///
/// The resource has a [state] named [ResourceState], that provides many useful
/// convenience methods to correctly handle the state of the resource.
///
/// The `on` method forces you to handle all the states of a Resource
/// (_ready_, _error_ and _loading_).
/// The are also other convenience methods to handle only specific states:
/// - `on` forces you to handle all the states of a Resource
/// - `maybeOn` lets you decide which states to handle and provide an `orElse`
/// action for unhandled states
/// - `map` equal to `on` but gives access to the `ResourceState` data class
/// - `maybeMap` equal to `maybeMap` but gives access to the `ResourceState`
/// data class
/// - `isReady` indicates if the `Resource` is in the ready state
/// - `isLoading` indicates if the `Resource` is in the loading state
/// - `hasError` indicates if the `Resource` is in the error state
/// - `asReady` upcast `ResourceState` into a `ResourceReady`, or return null if the `ResourceState` is in loading/error state
/// - `asError` upcast `ResourceState` into a `ResourceError`, or return null if the `ResourceState` is in loading/ready state
/// - `value` attempts to synchronously get the value of `ResourceReady`
/// - `error` attempts to synchronously get the error of `ResourceError`
///
/// A `Resource` provides the `resolve` and `refresh` methods.
///
/// The `resolve` method must be called only once for the lifecycle of the
/// resource.
/// If runs the `fetcher` for the first time and then it listen to the
/// [source], if provided.
/// If you're passing a [stream] it subscribes to it, and every time the source
/// changes, it resubscribes again.
///
/// The `refresh` method forces an update and calls the `fetcher` function
/// again or subscribes againg to the [stream].
/// {@endtemplate}
class Resource<T> extends SolidartSignal<ResourceState<T>> {
  /// {@macro resource}
  Resource(
    this.fetcher, {
    this.source,

    /// {@macro SignalBase.name}
    String? name,

    /// {@macro SignalBase.equals}
    super.equals,

    /// {@macro SignalBase.autoDispose}
    super.autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    super.trackInDevTools,

    /// Indicates whether the resource should be computed lazily, defaults to
    /// true.
    this.lazy = true,

    /// {@macro Resource.useRefreshing}
    bool? useRefreshing,

    /// Whether to track the previous state of the resource, defaults to true.
    bool? trackPreviousState,

    /// The debounce delay when the source changes, optional.
    this.debounceDelay,
  })  : useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
        stream = null,
        super(
          ResourceState<T>.loading(),
          name: name ?? nameFor('Resource'),
          trackPreviousValue:
              trackPreviousState ?? SolidartConfig.trackPreviousValue,
          comparator: identical,
        ) {
    // resolve the resource immediately if not lazy
    if (!lazy) _resolve();
  }

  /// {@macro resource}
  Resource.stream(
    this.stream, {
    this.source,

    /// {@macro SignalBase.name}
    String? name,

    /// {@macro SignalBase.equals}
    super.equals,

    /// {@macro SignalBase.autoDispose}
    super.autoDispose,

    /// {@macro SignalBase.trackInDevTools}
    super.trackInDevTools,

    /// Indicates whether the resource should be computed lazily, defaults to
    /// true.
    this.lazy = true,

    /// {@macro Resource.useRefreshing}
    bool? useRefreshing,

    /// Whether to track the previous state of the resource, defaults to true.
    bool? trackPreviousState,
    this.debounceDelay,
  })  : useRefreshing = useRefreshing ?? SolidartConfig.useRefreshing,
        fetcher = null,
        super(
          ResourceState<T>.loading(),
          name: name ?? nameFor('Resource'),
          trackPreviousValue:
              trackPreviousState ?? SolidartConfig.trackPreviousValue,
          comparator: identical,
        ) {
    // resolve the resource immediately if not lazy
    if (!lazy) _resolve();
  }

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

  StreamSubscription<T>? _streamSubscription;

  // The source dispose observation
  DisposeObservation? _sourceDisposeObservation;

  /// Indicates if the resource has been resolved
  bool _resolved = false;

  /// {@template Resource.useRefreshing}
  /// Whether to use `isRefreshing` in the current state of the resource,
  /// defaults to true.
  ///
  /// If you set to false, the state will always transition to `loading` when
  /// refreshing.
  /// {@endtemplate}
  final bool useRefreshing;

  /// The current resource state
  ResourceState<T> get state {
    _resolveIfNeeded();
    return super.value;
  }

  /// The current resource state
  @override
  ResourceState<T> call() => state;

  /// Updates the current resource state
  set state(ResourceState<T> state) => super.value = state;

  // coverage:ignore-start
  @Deprecated('Use state instead')
  @override
  ResourceState<T> get value => state;

  @Deprecated('Use state instead')
  @override
  set value(ResourceState<T> value) => state = value;

  @Deprecated('Use previousState instead')
  @override
  ResourceState<T>? get previousValue => previousState;

  @Deprecated('Use untrackedState instead')
  @override
  ResourceState<T> get untrackedValue => untrackedState;

  @Deprecated('Use untrackedPreviousState instead')
  @override
  ResourceState<T>? get untrackedPreviousValue => untrackedPreviousState;

  @Deprecated('Use update instead')
  @override
  ResourceState<T> updateValue(
    ResourceState<T> Function(ResourceState<T> state) callback,
  ) =>
      update(callback);
  // coverage:ignore-end

  /// The previous resource state
  ResourceState<T>? get previousState {
    _resolveIfNeeded();
    if (!_resolved) return null;
    return super.previousValue;
  }

  /// The previous resource state, without tracking
  ResourceState<T>? get untrackedPreviousState => super.untrackedPreviousValue;

  /// The resource state without tracking
  ResourceState<T> get untrackedState => super.untrackedValue;

  // The stream trasformed in a broadcast stream, if needed
  Stream<T> get _stream {
    final s = stream!();
    if (!_broadcastStreams.keys.contains(s)) {
      _broadcastStreams[s] = s.isBroadcast
          ? s
          : s.asBroadcastStream(
              onListen: (subscription) {
                if (!_streamSubscriptions.contains(subscription)) {
                  _streamSubscriptions.add(subscription);
                }
                subscription.resume();
              },
              onCancel: (subscription) {
                subscription.pause();
              },
            );
    }
    return _broadcastStreams[s]!;
  }

  final _broadcastStreams = <Stream<T>, Stream<T>>{};
  final _streamSubscriptions = <StreamSubscription<T>>[];

  /// Resolves the [Resource].
  ///
  /// If you provided a [fetcher], it run the async call.
  /// Otherwise it starts listening to the [stream].
  ///
  /// Then will subscribe to the [source], if provided.
  ///
  /// This method must be called once during the life cycle of the resource.
  Future<void> _resolve() async {
    assert(
      _resolved == false,
      """The resource has been already resolved, you can't resolve it more than once. Use `refresh()` instead if you want to refresh the value.""",
    );
    _resolved = true;

    if (fetcher != null) {
      // start fetching
      await _fetch();
    }
    // React the the [stream], if provided
    if (stream != null) {
      _subscribe();
    }

    // react to the [source], if provided.
    if (source != null) {
      _sourceDisposeObservation = source!.observe((p, v) {
        if (debounceDelay != null) {
          Debouncer.debounce(
            source!.name,
            debounceDelay!,
            refresh,
          );
        } else {
          refresh();
        }
      });
      source!.onDispose(_sourceDisposeObservation!);
    }
  }

  /// Resolves the resource, if needed
  void _resolveIfNeeded() {
    if (!_resolved) _resolve();
  }

  /// Runs the [fetcher] for the first time.
  Future<void> _fetch() async {
    assert(fetcher != null, 'You are trying to fetch, but fetcher is null');
    try {
      final result = await fetcher!();
      state = ResourceState<T>.ready(result);
    } catch (e, s) {
      state = ResourceState<T>.error(e, stackTrace: s);
    }
  }

  /// Subscribes to the provided [stream] for the first time.
  void _subscribe() {
    assert(
      stream != null,
      'You are trying to listen to a stream, but stream is null',
    );
    _listenStream();
  }

  /// Listens to the stream
  void _listenStream() {
    _streamSubscription = _stream.listen(
      (data) {
        state = ResourceState<T>.ready(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = ResourceState<T>.error(error, stackTrace: stackTrace);
      },
    );
  }

  /// Forces a refresh of the [fetcher] or the [stream].
  ///
  /// In case of the [stream], cancels the previous subscription and
  /// resubscribes.
  Future<void> refresh() async {
    if (fetcher != null) {
      return _refetch();
    }
    return _resubscribe();
  }

  /// Resubscribes to the [stream].
  ///
  /// Cancels the previous subscription and resubscribes.
  void _resubscribe() {
    assert(
      stream != null,
      'You are trying to listen to a stream, but stream is null',
    );
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _transition();
    _listenStream();
  }

  // Transitions to the refreshing state, if enabled, otherwise sets the state
  // to loading.
  void _transition() {
    if (useRefreshing) {
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
    } else {
      state = ResourceState<T>.loading();
    }
  }

  /// Force a refresh of the [fetcher].
  Future<void> _refetch() async {
    assert(fetcher != null, 'You are trying to refetch, but fetcher is null');
    try {
      _transition();
      final result = await fetcher!();
      state = ResourceState<T>.ready(result);
    } catch (e, s) {
      state = ResourceState<T>.error(e, stackTrace: s);
    }
  }

  /// Returns a future that completes with the value when the Resource is ready
  /// If the resource is already ready, it completes immediately.
  FutureOr<T> untilReady() async {
    final state = await until((value) => value.isReady);
    return state.asReady!.value;
  }

  /// Calls a function with the current [state] and assigns the result as the
  /// new state
  ResourceState<T> update(
    ResourceState<T> Function(ResourceState<T> state) callback,
  ) =>
      state = callback(_value);

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _streamSubscriptions.clear();

    _sourceDisposeObservation?.call();
    _broadcastStreams.clear();
    _streamSubscriptions.clear();
    // Dispose the source, if needed
    if (source != null) {
      if (source!.autoDispose && source!.listenerCount == 0) {
        source!.dispose();
      }
    }
    super.dispose();
  }

  @override
  String toString() =>
      '''Resource<$T>(state: $_value, previousState: $_previousValue)''';
}
