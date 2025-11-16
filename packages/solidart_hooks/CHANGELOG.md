## 3.1.2

### Changes from solidart

- **REFACTOR**: Improve the Solidart DevTools extension by giving any signal an id and omit overriding the same signal by name.

## 3.1.1

### Changes from solidart

- **FIX**: Expose `until` method for `Computed`.

## 3.1.0

### Changes from solidart

- **REFACTOR**: Deprecate `maybeOn` and `on` methods of `ResourceState`. Use `maybeWhen` and `when` instead.

## 3.0.0

- **BREAKING CHANGE**: `SignalHook` no longer calls `setState` to trigger a rebuild when the signal changes. Instead, you should use `SignalBuilder` to listen to signal changes and rebuild the UI accordingly. This change improves performance and reduces unnecessary rebuilds. You can also use `useListenable` if you want to trigger a rebuild on signal changes.
  ### Migration Guide

  **Before (v2.x):**
  ```dart
  final count = useSignal(0);
  return Text('Count: ${count.value}'); // Auto-rebuilds
  ```
  **After (v3.x):**
  ```dart
  final count = useSignal(0);
  return SignalBuilder(
    builder: (context, child) => Text('Count: ${count.value}'),
  );
  ```

  Or use `useListenable` for full widget rebuild:
  ```dart
  final count = useSignal(0);
  useListenable(count);
  return Text('Count: ${count.value}');
  ```
  This is inline with the behaviour of `useValueNotifier` from `flutter_hooks`.

## 2.0.0

- **FEAT**: Added `useResource`, `useResourceStream`, `useListSignal`, `useSetSignal` and `useMapSignal` hooks.
- **CHORE**: Export `flutter_solidart` package.

## 1.0.0+1

- **CHORE**: Move example to `packages/solidart_hooks/example` to be compatible with pub.dev requirements.

## 1.0.0

- Initial release of solidart Hooks.
