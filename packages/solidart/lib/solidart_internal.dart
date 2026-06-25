/// Internal API shared with sibling packages (e.g. `flutter_solidart`).
///
/// This is **not** part of solidart's public API: the symbols here expose
/// internal `alien_signals` types and may change without a major version bump.
/// Application code must not import this library.
library;

export 'src/core/core.dart' show ReactiveSystem, reactiveSystem;
