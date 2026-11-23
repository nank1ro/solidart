import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

void main() {
  group('DevTools inspection does not change computed lifecycle (#185)', () {
    setUp(() => SolidartConfig.devToolsEnabled = true);
    tearDown(() => SolidartConfig.devToolsEnabled = false);

    test(
      'a dependency-free autoDispose Computed is not disposed at creation',
      () {
        final constant = Computed(() => 1, autoDispose: true);
        expect(
          constant.disposed,
          isFalse,
          reason: 'inspecting a signal for DevTools must not dispose it',
        );
        expect(constant.value, 1);
      },
    );

    test(
      'an autoDispose Computed with a dependency is not disposed at creation',
      () {
        final source = Signal(1);
        final doubled = Computed(() => source.value * 2, autoDispose: true);
        expect(doubled.disposed, isFalse);
        expect(doubled.value, 2);
        source.dispose();
      },
    );

    test('matches the behavior observed with DevTools disabled', () {
      SolidartConfig.devToolsEnabled = false;
      final plain = Computed(() => 1, autoDispose: true);
      expect(plain.disposed, isFalse);
    });
  });
}
