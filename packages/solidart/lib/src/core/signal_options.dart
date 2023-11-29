part of 'core.dart';

/// A custom comparator function
typedef ValueComparator<T> = bool Function(T a, T b);

/// {@template signaloptions}
/// Signal options which increase its customization
///
/// The [equals] field if true performs an equality check `==`
/// before updating the signal value.
/// If the current and the new value are equal, no updates occur.

/// The [comparator] field is taken into account only if [equals] is false.
/// It performs an equality check by calling the custom comparator
/// you passed in.
/// If the current and the new value are equal, no updates occur.
/// The default value of a [comparator] is [identical] that checks
/// the object references.
/// {@endtemplate}
@immutable
class SignalOptions<T> {
  /// {@macro signaloptions}
  const SignalOptions({
    this.name,
    this.equals = false,
    this.comparator = identical,
    this.autoDispose = true,
  });

  /// Whether to check the equality of the value with the == equality.
  ///
  /// Preventing signal updates if the new value is equal to the previous.
  ///
  /// When this value is true, the [comparator] is not used.
  final bool equals;

  /// An optional comparator function, defaults to [identical].
  ///
  /// Preventing signal updates if the [comparator] returns true.
  ///
  /// Taken into account only if [equals] is false.
  final ValueComparator<T?>? comparator;

  /// The name of the signal, useful for logging purposes.
  final String? name;

  /// Whether to automatically dispose the signal (defaults to true).
  ///
  /// This happens automatically when there are no longer subscribers.
  /// If you set it to false, you should remember to dispose the signal manually
  final bool autoDispose;

  @override
  String toString() =>
      '''SignalOptions<$T>(name: $name, equals: $equals, comparator: ${comparator != null ? "PRESENT" : "MISSING"}, autoDispose: $autoDispose)''';
}

/// {@template resource-options}
/// {@macro signaloptions}
///
/// The [lazy] parameter indicates if the resource should be computed
/// lazily, defaults to true.
/// {@endtemplate}
class ResourceOptions {
  /// {@macro resource-options}
  const ResourceOptions({
    this.name,
    this.lazy = true,
    this.autoDispose = true,
  });

  /// Indicates whether the resource should be computed lazily, defaults to true
  final bool lazy;

  /// The name of the signal, useful for logging purposes.
  final String? name;

  /// Whether to automatically dispose the resource (defaults to true).
  ///
  /// This happens automatically when there are no longer subscribers.
  /// If you set it to false, you should remember to dispose the resource
  /// manually
  final bool autoDispose;

  /// coverage:ignore-start
  /// Converts the [ResourceOptions] to a [SignalOptions].
  @internal
  SignalOptions<ResourceState<T>> toSignalOptions<T>() {
    return SignalOptions<ResourceState<T>>(
      name: name,
      autoDispose: autoDispose,
    );
  }

  /// coverage:ignore-end
}
