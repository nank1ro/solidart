// Guards the assumption baked into `reactive_system.dart` that alien_signals'
// internal `hasChildEffect` flag is the bit `64`. That constant is hidden from
// alien_signals' public barrel, so solidart redeclares it. If upstream ever
// changes the value, child-effect disposal would break silently — this test
// fails loudly instead.
import 'package:alien_signals/src/preset.dart' as alien_preset;
import 'package:test/test.dart';

void main() {
  test('alien_signals hasChildEffect flag is still 64', () {
    // Must match `_hasChildEffect = 64` in reactive_system.dart.
    expect(alien_preset.hasChildEffect, 64);
  });
}
