class SolidartMemoized<T> {
  SolidartMemoized({
    required this.value,
    SolidartMemoized? head,
    this.next,
    this.prev,
  }) {
    this.head = head ?? this;
  }

  final T value;

  SolidartMemoized? next;
  SolidartMemoized? prev;

  late SolidartMemoized head;

  bool valueOf<V>() => value is V;
}

abstract interface class SolidartMemoizedElement {
  abstract SolidartMemoized memoized;
}
