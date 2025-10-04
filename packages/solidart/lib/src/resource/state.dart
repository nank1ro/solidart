import 'package:meta/meta.dart';

/// Manages all the different states of a [Resource]:
/// - ResourceReady
/// - ResourceLoading
/// - ResourceError
@sealed
@immutable
sealed class ResourceState<T> {
  /// Creates an [ResourceState] with a data.
  ///
  /// The data can be `null`.
  const factory ResourceState.ready(T data, {bool isRefreshing}) =
      ResourceReady<T>;

  /// Creates an [ResourceState] in loading state.
  ///
  /// Prefer always using this constructor with the `const` keyword.
  // coverage:ignore-start
  const factory ResourceState.loading() = ResourceLoading<T>;
  // coverage:ignore-end

  /// Creates an [ResourceState] in error state.
  ///
  /// The parameter [error] cannot be `null`.
  // coverage:ignore-start
  const factory ResourceState.error(
    Object error, {
    StackTrace? stackTrace,
    bool isRefreshing,
  }) = ResourceError<T>;
  // coverage:ignore-end

  /// private mapper, so that classes inheriting Resource can specify their own
  /// `map` method with different parameters.
  // coverage:ignore-start
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  });
  // coverage:ignore-end
}

/// Creates an [ResourceState] in ready state with a data.
@immutable
class ResourceReady<T> implements ResourceState<T> {
  /// Creates an [ResourceState] with a data.
  const ResourceReady(this.value, {this.isRefreshing = false});

  /// The value currently exposed.
  final T value;

  /// Indicates if the data is being refreshed, defaults to false.
  final bool isRefreshing;

  // coverage:ignore-start
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
    return 'ResourceReady<$T>(value: $value, refreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceReady<T> &&
        other.value == value &&
        other.isRefreshing == isRefreshing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, isRefreshing);

  /// Convenience method to update the values of a [ResourceReady].
  ResourceReady<T> copyWith({
    T? value,
    bool? isRefreshing,
  }) {
    return ResourceReady<T>(
      value ?? this.value,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
  // coverage:ignore-end
}

/// {@template resourceloading}
/// Creates an [ResourceState] in loading state.
///
/// Prefer always using this constructor with the `const` keyword.
/// {@endtemplate}
@immutable
class ResourceLoading<T> implements ResourceState<T> {
  /// {@macro resourceloading}
  const ResourceLoading();

  // coverage:ignore-start
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
  // coverage:ignore-end
}

/// {@template resourceerror}
/// Creates an [ResourceState] in error state.
///
/// The parameter [error] cannot be `null`.
/// {@endtemplate}
@immutable
class ResourceError<T> implements ResourceState<T> {
  /// {@macro resourceerror}
  const ResourceError(
    this.error, {
    this.stackTrace,
    this.isRefreshing = false,
  });

  /// The error.
  final Object error;

  /// The stackTrace of [error], optional.
  final StackTrace? stackTrace;

  /// Indicates if the data is being refreshed, defaults to false.
  final bool isRefreshing;

  // coverage:ignore-start
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
    return 'ResourceError<$T>(error: $error, stackTrace: $stackTrace, '
        'refreshing: $isRefreshing)';
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceError<T> &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.isRefreshing == isRefreshing;
  }

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace, isRefreshing);

  /// Convenience method to update the [isRefreshing] value of a [Resource]
  ResourceError<T> copyWith({
    Object? error,
    StackTrace? stackTrace,
    bool? isRefreshing,
  }) {
    return ResourceError<T>(
      error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
  // coverage:ignore-end
}

/// Some useful extension available on any [ResourceState].
// coverage:ignore-start
extension ResourceExtensions<T> on ResourceState<T> {
  /// Indicates if the resource is loading.
  bool get isLoading => this is ResourceLoading<T>;

  /// Indicates if the resource has an error.
  bool get hasError => this is ResourceError<T>;

  /// Indicates if the resource is ready.
  bool get isReady => this is ResourceReady<T>;

  /// Indicates if the resource is refreshing. Loading is not considered as
  /// refreshing.
  bool get isRefreshing => switch (this) {
        ResourceReady<T>(:final isRefreshing) => isRefreshing,
        ResourceError<T>(:final isRefreshing) => isRefreshing,
        ResourceLoading<T>() => false,
      };

  /// Upcast [ResourceState] into a [ResourceReady], or return null if the
  /// [ResourceState] is in loading/error state.
  ResourceReady<T>? get asReady {
    return map(
      ready: (r) => r,
      error: (_) => null,
      loading: (_) => null,
    );
  }

  /// Upcast [ResourceState] into a [ResourceError], or return null if the
  /// [ResourceState] is in ready/loading state.
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

  /// Perform some actions based on the state of the [ResourceState], or call
  /// orElse if the current state is not considered.
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

  /// Performs an action based on the state of the [ResourceState].
  ///
  /// All cases are required.
  R on<R>({
    // ignore: avoid_positional_boolean_parameters
    required R Function(T data) ready,
    // ignore: avoid_positional_boolean_parameters
    required R Function(Object error, StackTrace? stackTrace) error,
    required R Function() loading,
  }) {
    return map(
      ready: (r) => ready(r.value),
      error: (e) => error(e.error, e.stackTrace),
      loading: (l) => loading(),
    );
  }

  /// Performs an action based on the state of the [ResourceState], or call
  /// [orElse] if the current state is not considered.
  R maybeOn<R>({
    required R Function() orElse,
    // ignore: avoid_positional_boolean_parameters
    R Function(T data)? ready,
    // ignore: avoid_positional_boolean_parameters
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
}
