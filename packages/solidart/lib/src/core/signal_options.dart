typedef ValueComparator<T> = bool Function(T a, T b);

/// Signal options which increase its customization
class SignalOptions<T> {
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
