part of '../solidart.dart';

/// Error state containing an error and optional stack trace.
@immutable
class ResourceError<T> implements ResourceState<T> {
  /// Creates an error state.
  const ResourceError(
    this.error, {
    this.stackTrace,
    this.isRefreshing = false,
  });

  /// The error object.
  final Object error;

  /// Optional stack trace.
  final StackTrace? stackTrace;

  /// Whether the resource is refreshing.
  final bool isRefreshing;

  @override
  int get hashCode => Object.hash(runtimeType, error, stackTrace, isRefreshing);

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceError<T> &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.isRefreshing == isRefreshing;
  }

  /// Returns a copy with updated fields.
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
}

/// Loading state.
@immutable
class ResourceLoading<T> implements ResourceState<T> {
  /// Creates a loading state.
  const ResourceLoading();

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  }) {
    return loading(this);
  }

  @override
  String toString() => 'ResourceLoading<$T>()';
}

/// Ready state containing data.
@immutable
class ResourceReady<T> implements ResourceState<T> {
  /// Creates a ready state with [value].
  const ResourceReady(this.value, {this.isRefreshing = false});

  /// The resource value.
  final T value;

  /// Whether the resource is refreshing.
  final bool isRefreshing;

  @override
  int get hashCode => Object.hash(runtimeType, value, isRefreshing);

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is ResourceReady<T> &&
        other.value == value &&
        other.isRefreshing == isRefreshing;
  }

  /// Returns a copy with updated fields.
  ResourceReady<T> copyWith({
    T? value,
    bool? isRefreshing,
  }) {
    return ResourceReady<T>(
      value ?? this.value,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

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
}

/// {@template solidart.resource-state}
/// Represents the state of a [Resource].
///
/// A resource is always in one of:
/// - `ready(data)` when a value is available
/// - `loading()` while work is in progress
/// - `error(error)` when a failure occurs
///
/// Use [ResourceStateExtensions] helpers to map or pattern-match:
/// ```dart
/// final state = resource.state;
/// final label = state.when(
///   ready: (data) => 'ready: $data',
///   error: (err, _) => 'error: $err',
///   loading: () => 'loading',
/// );
/// ```
/// {@endtemplate}
@sealed
@immutable
sealed class ResourceState<T> {
  /// Base constructor for resource states.
  const ResourceState(); // coverage:ignore-line

  /// {@macro solidart.resource-state}
  ///
  /// Creates an error state.
  const factory ResourceState.error(
    Object error, {
    StackTrace? stackTrace,
    bool isRefreshing,
  }) = ResourceError<T>;

  /// {@macro solidart.resource-state}
  ///
  /// Creates a loading state.
  const factory ResourceState.loading() = ResourceLoading<T>;

  /// {@macro solidart.resource-state}
  ///
  /// Creates a ready state with [data].
  const factory ResourceState.ready(T data, {bool isRefreshing}) =
      ResourceReady<T>;

  /// Maps each concrete state to a value.
  R map<R>({
    required R Function(ResourceReady<T> ready) ready,
    required R Function(ResourceError<T> error) error,
    required R Function(ResourceLoading<T> loading) loading,
  });
}
