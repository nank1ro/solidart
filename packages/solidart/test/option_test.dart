import 'package:solidart/src/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('Option', () {
    test('Some.unwrap() returns value', () {
      const some = Some(42);
      expect(some.unwrap(), 42);
    });

    test('None.unwrap() throws StateError', () {
      const none = None<int>();
      expect(none.unwrap, throwsStateError);
    });

    test('Some.safeUnwrap() returns value', () {
      const some = Some(42);
      expect(some.safeUnwrap(), 42);
    });

    test('None.safeUnwrap() returns null', () {
      const none = None<int>();
      expect(none.safeUnwrap(), isNull);
    });
  });
}
