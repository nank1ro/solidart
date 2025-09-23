import '../core/memoized.dart';

SolidartMemoizedElement? _activeElement;

SolidartMemoizedElement? getCurrentElement() => _activeElement;

SolidartMemoizedElement? setCurrentElement(SolidartMemoizedElement? element) {
  final prevElement = _activeElement;
  _activeElement = element;

  return prevElement;
}
