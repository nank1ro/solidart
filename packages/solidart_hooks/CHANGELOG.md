## 3.0.0

- **BREAKING CHANGE**: `SignalHook` no longer calls `setState` to trigger a rebuild when the signal changes. Instead, you should use `SignalBuilder` to listen to signal changes and rebuild the UI accordingly. This change improves performance and reduces unnecessary rebuilds. You can also use `useListenable` if you want to trigger a rebuild on signal changes.

## 2.0.0

- **FEAT**: Added `useResource`, `useResourceStream`, `useListSignal`, `useSetSignal` and `useMapSignal` hooks.
- **CHORE**: Export `flutter_solidart` package.

## 1.0.0+1

- **CHORE**: Move example to `packages/solidart_hooks/example` to be compatible with pub.dev requirements.

## 1.0.0

- Initial release of solidart Hooks.
