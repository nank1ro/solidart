## 2.0.3

- Update analyzer dependency range to support latest Dart versions (thanks to @romaingyh).

## 2.0.2

- Fix lints not working with latest Dart versions.

## 2.0.1

- Rename `Wrap with Solid` assist to `Wrap with ProviderScope`

## 2.0.0

- Replace `Wrap with Solid` assist with `Wrap with ProviderScope` (if you use `disco`)
- Fix `LintCode` issue (thanks to @manuel-plavsic)
- Remove the deprecated `invalid_observe_type` lint
- Remove `Wrap with ResourceBuilder` assist
- Fix `LintCode` issue (thanks to @manuel-plavsic)
- Remove the deprecated `invalid_observe_type` lint
- Remove `Wrap with ResourceBuilder` assist

## 2.0.0-dev.3

- Fix `LintCode` issue (thanks to @manuel-plavsic)
- Remove the deprecated `invalid_observe_type` lint
- Remove `Wrap with ResourceBuilder` assist

## 2.0.0-dev.2

- Fix `LintCode` issue (thanks to @manuel-plavsic)

## 2.0.0-dev.1

- Remove the deprecated `invalid_observe_type` lint
- Remove `Wrap with ResourceBuilder` assist

## 1.1.2

- Fix `LintCode` issue (thanks to @manuel-plavsic)

## 1.1.1

- Update dependencies

## 1.1.0

- **CHORE**: Update `flutter_solidart` dependency
- **CHORE**: Remove `avoid_dynamic_solid_signal`
- **REFACTOR**: Rename `avoid_dynamic_solid_provider` into `avoid_dynamic_provider`

## 1.0.1

- Update dependencies

## 1.0.0

- Rename ResourceValue into ResourceState
- **BUGFIX** Remove `isRefreshing` from ResourceBuilder assist
- **CHORE**: Update `flutter_solidart` dependency, update `avoid_dynamic_solid_signal` lint and remove unnecessary lints
- **BUGFIX**: Fix issues with the `invalid_observe_type` and `invalid_update_type` lints not linting for a dynamic type

## 1.0.0-dev5

- **BUGFIX**: Fix issues with the `invalid_observe_type` and `invalid_update_type` lints not linting for a dynamic type

## 1.0.0-dev4

- **CHORE**: Update `flutter_solidart` dependency, update `avoid_dynamic_solid_signal` lint and remove unnecessary lints

## 1.0.0-dev3

- **BUGFIX** Remove `isRefreshing` from ResourceBuilder assist

## 1.0.0-dev2

Rename ResourceValue into ResourceState

## 1.0.0-dev1

Fix lints for the development preview of solidart 1.0.0

## 0.2.0

- Update `flutter_solidart` and fix deprecated fields

## 0.1.3

Add the following lints:

- invalid_update_type
- invalid_observe_type

## 0.1.2

- Fix dynamic solid signal quickfix

## 0.1.1

- Fix dynamic SolidProvider type fix position

## 0.1.0

- First release of **solidart_lint** with the following **assists**:

  - Wrap with Solid
  - Wrap with SignalBuilder
  - Wrap with ResourceBuilder
  - Wrap with Show

  and **lints**:

  - avoid_dynamic_solid_provider
  - avoid_dynamic_solid_signal
  - invalid_provider_type
  - invalid_signal_type
  - missing_solid_get_type
