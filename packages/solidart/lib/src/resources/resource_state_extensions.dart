part of '../solidart.dart';

/// Convenience accessors for [ResourceState].
///
/// Includes common flags (`isLoading`, `isReady`, `hasError`), casting helpers
/// (`asReady`, `asError`), and pattern matching helpers (`when`, `maybeWhen`,
/// `maybeMap`).
extension ResourceStateExtensions<T> on ResourceState<T> {
  /// Casts to [ResourceError] if possible.
  ResourceError<T>? get asError => map(
    error: (e) => e,
    ready: (_) => null,
    loading: (_) => null,
  );

  /// Casts to [ResourceReady] if possible.
  ResourceReady<T>? get asReady => map(
    ready: (r) => r,
    error: (_) => null,
    loading: (_) => null,
  );

  /// Returns the error for error state.
  Object? get error => map(
    error: (r) => r.error,
    ready: (_) => null,
    loading: (_) => null,
  );

  /// Whether this state is an error.
  bool get hasError => this is ResourceError<T>;

  /// Whether this state is loading.
  bool get isLoading => this is ResourceLoading<T>;

  /// Whether this state is ready.
  bool get isReady => this is ResourceReady<T>;

  /// Whether this state is marked as refreshing.
  bool get isRefreshing => switch (this) {
    ResourceReady<T>(:final isRefreshing) => isRefreshing,
    ResourceError<T>(:final isRefreshing) => isRefreshing,
    ResourceLoading<T>() => false,
  };

  /// Returns the value for ready state, throws for error state.
  T? get value => map(
    ready: (r) => r.value,
    // ignore: only_throw_errors
    error: (r) => throw r.error,
    loading: (_) => null,
  );

  /// Executes callbacks for available handlers, otherwise [orElse].
  R maybeMap<R>({
    required R Function() orElse,
    R Function(ResourceReady<T> ready)? ready,
    R Function(ResourceError<T> error)? error,
    R Function(ResourceLoading<T> loading)? loading,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r);
        return orElse();
      },
      error: (e) {
        if (error != null) return error(e);
        return orElse();
      },
      loading: (l) {
        if (loading != null) return loading(l);
        return orElse();
      },
    );
  }

  /// Executes callbacks for available handlers, otherwise [orElse].
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T data)? ready,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function()? loading,
  }) {
    return map(
      ready: (r) {
        if (ready != null) return ready(r.value);
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

  /// Executes callbacks for each state.
  R when<R>({
    required R Function(T data) ready,
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function() loading,
  }) {
    return map(
      ready: (r) => ready(r.value),
      error: (e) => error(e.error, e.stackTrace),
      loading: (_) => loading(),
    );
  }
}
