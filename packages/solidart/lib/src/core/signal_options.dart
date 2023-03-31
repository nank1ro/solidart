import 'package:meta/meta.dart';

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
    this.equals = false,
    this.comparator = identical,
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
  final ValueComparator<T>? comparator;

  @override
  String toString() =>
      '''SignalOptions<$T>(equals: $equals, comparator: ${comparator != null ? "PRESENT" : "MISSING"})''';
}
