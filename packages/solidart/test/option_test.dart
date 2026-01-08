import 'package:solidart/src/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('Option', () {
    test('Some.unwrap() returns value', () {
      final some = Some(42);
      expect(some.unwrap(), 42);
    });

    test('None.unwrap() throws StateError', () {
      final none = None<int>();
      expect(() => none.unwrap(), throwsStateError);
    });

    test('Some.safeUnwrap() returns value', () {
      final some = Some(42);
      expect(some.safeUnwrap(), 42);
    });

    test('None.safeUnwrap() returns null', () {
      final none = None<int>();
      expect(none.safeUnwrap(), isNull);
    });
  });
}
