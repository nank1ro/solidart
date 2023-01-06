import 'package:meta/meta.dart';
import 'package:solidart/src/core/signal.dart';
import 'package:solidart/src/core/signal_base.dart';

/// Creates a resource that wraps a repeated promise in a reactive pattern:
Resource<T, R> createResource<T, R>({
  Signal<T>? source,
  required Future<R> Function() fetcher,
}) {
  return Resource<T, R>(
    source: source,
    fetcher: fetcher,
  );
}

class Resource<T, R> extends Signal<ResourceValue<R>> {
  Resource({
    this.source,
    required this.fetcher,
    super.options,
  }) : super(ResourceValue<R>.unresolved()) {
    _initialize();
  }

  /// Reactive signal values passed to the fetcher, optional
  final SignalBase<T>? source;

  // The asynchrounous function used to retrieve data.
  final Future<R> Function() fetcher;

  // React to the [source], if provided.
  void _initialize() {
    if (source != null) {
      source!.addListener(fetch);
      source!.onDispose(() => source!.removeListener(fetch));
    }
  }

  /// Runs the [fetcher] for the first time.
  ///
  /// You may not use this method directly on Flutter apps because the operation is already
  /// performed by [ResourceBuilder].
  Future<void> fetch() async {
    try {
      value = const ResourceValue.loading();
      final result = await fetcher();
      value = ResourceValue.ready(result);
    } catch (e, s) {
      value = ResourceValue.error(e, stackTrace: s);
    }
  }

  /// Force a refresh of the [fetcher].
  Future<void> refetch() async {
    try {
      if (value is ResourceReady) {
        update(
          (value) => (value as ResourceReady<R>).copyWith(refreshing: true),
        );
      } else {
        value = const ResourceValue.loading();
      }
      final result = await fetcher();
      value = ResourceValue.ready(result);
    } catch (e, s) {
      value = ResourceValue.error(e, stackTrace: s);
    }
  }
}

@sealed
@immutable
abstract class ResourceValue<T> {
  const factory ResourceValue.unresolved() = ResourceUnresolved<T>;

  /// Creates an [ResourceValue] with a data.
  ///
  /// The data can be `null`.
  const factory ResourceValue.ready(T data) = ResourceReady<T>;

  /// Creates an [ResourceValue] in loading state.
  ///
  /// Prefer always using this constructor with the `const` keyword.
  // coverage:ignore-start
  const factory ResourceValue.loading() = ResourceLoading<T>;
  // coverage:ignore-end

  /// Creates an [ResourceValue] in error state.
  ///
  /// The parameter [error] cannot be `null`.
  // coverage:ignore-start
  const factory ResourceValue.error(Object error, {StackTrace? stackTrace}) =
      ResourceError<T>;
  // private mapper, so thast classes inheriting Resource can specify their own
  // `map` method with different parameters.
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  });
}

/// Creates an [ResourceValue] in ready state with a data.
@immutable
class ResourceReady<T> implements ResourceValue<T> {
  /// Creates an [ResourceValue] with a data.
  const ResourceReady(this.value, {this.refreshing = false});

  /// The value currently exposed.
  final T value;

  /// Indicates if the data is being refreshed, defaults to false.
  final bool refreshing;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return ready(this);
  }

  @override
  String toString() {
    return 'ResourceReady<$T>(value: $value, refreshing: $refreshing)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceReady<T> &&
        other.value == value &&
        other.refreshing == refreshing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, refreshing);

  ResourceReady<T> copyWith({
    bool? refreshing,
  }) {
    return ResourceReady(
      value,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

/// Creates an [ResourceValue] in loading state.
///
/// Prefer always using this constructor with the `const` keyword.
@immutable
class ResourceLoading<T> implements ResourceValue<T> {
  const ResourceLoading();

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return loading(this);
  }

  @override
  String toString() {
    return 'ResourceLoading<$T>()';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Creates an [ResourceValue] in error state.
///
/// The parameter [error] cannot be `null`.
@immutable
class ResourceError<T> implements ResourceValue<T> {
  const ResourceError(
    this.error, {
    this.stackTrace,
  });

  /// The error.
  final Object error;

  /// The stackTrace of [error], optional.
  final StackTrace? stackTrace;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return error(this);
  }

  @override
  String toString() {
    return 'ResourceError<$T>(error: $error, stackTrace: $stackTrace)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceError<T> &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace);
}

/// Creates an [ResourceValue] in unresolved state.
@immutable
class ResourceUnresolved<T> implements ResourceValue<T> {
  const ResourceUnresolved();

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    throw Exception('Cannot map an unresolved resource');
  }

  @override
  String toString() {
    return 'ResourceUnresolved<$T>()';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

extension ResourceExtensions<T> on ResourceValue<T> {
  /// Indicates if the resoruce is loading.
  bool get isLoading => this is ResourceLoading<T>;

  /// Indicates if the resoruce has an error.
  bool get hasError => this is ResourceError<T>;

  /// Indicates if the resoruce is ready.
  bool get isReady => this is ResourceReady<T>;

  /// Upcast [ResourceValue] into a [ResourceReady], or return null if the
  /// [ResourceValue] is in loading/error state.
  ResourceReady<T>? get asReady {
    return map(
      ready: (r) => r,
      error: (_) => null,
      loading: (_) => null,
    );
  }

  /// Upcast [ResourceValue] into a [ResourceError], or return null if the
  /// [ResourceValue] is in ready/loading state.
  ResourceError<T>? get asError {
    return map(
      error: (e) => e,
      ready: (_) => null,
      loading: (_) => null,
    );
  }

  /// Attempts to synchronously get the value of [ResourceReady].
  ///
  /// On error, this will rethrow the error.
  /// If loading, will return `null`.
  T? get value {
    return map(
      ready: (r) => r.value,
      // ignore: only_throw_errors
      error: (r) => throw r.error,
      loading: (_) => null,
    );
  }

  /// Attempts to synchronously get the error of [ResourceError].
  ///
  /// On other states will return `null`.
  Object? get error {
    return map(
      error: (r) => r.error,
      ready: (_) => null,
      loading: (_) => null,
    );
  }

  /// Perform some actions based on the state of the [ResourceValue], or call orElse
  /// if the current state is not considered.
  R maybeMap<R>({
    R Function(ResourceReady<T> ready)? ready,
    R Function(ResourceError<T> error)? error,
    R Function(ResourceLoading<T> loading)? loading,
    required R Function() orElse,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r);
        return orElse();
      },
      error: (d) {
        if (error != null) return error(d);
        return orElse();
      },
      loading: (l) {
        if (loading != null) return loading(l);
        return orElse();
      },
    );
  }

  /// Performs an action based on the state of the [ResourceValue].
  ///
  /// All cases are required.
  R on<R>({
    required R Function(T data, bool refreshing) ready,
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function() loading,
  }) {
    return map(
      ready: (r) => ready(r.value, r.refreshing),
      error: (e) => error(e.error, e.stackTrace),
      loading: (l) => loading(),
    );
  }

  /// Performs an action based on the state of the [ResourceValue], or call [orElse]
  /// if the current state is not considered.
  R maybeOn<R>({
    R Function(T data, bool refreshing)? ready,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function()? loading,
    required R Function() orElse,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r.value, r.refreshing);
        return orElse();
      },
      error: (e) {
        if (error != null) return error(e.error, e.stackTrace);
        return orElse();
      },
      loading: (l) {
        if (loading != null) return loading();
        return orElse();
      },
    );
  }
}
