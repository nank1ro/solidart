## 1.0.0-dev1

This is a development preview of the 1.0.0 release of solidart.
The core of the library has been rewritten in order to support automatic dependency tracking like SolidJS.

- **FEAT**: Add automatic dependency tracking
- **BREAKING CHANGE**: To create derived signals now you should use `createComputed` instead of `signalName.select`
  This allows you to derive from many signals instead of only 1.

  _Before_:

  ```dart
  final count = createSignal(0);
  final doubleCount = count.select((value) => value * 2);
  ```

  _Now_:

  ```dart
  final count = createSignal(0);
  final doubleCount = createComputed(() => count() * 2);
  ```

- **FEAT**: The `createEffect` no longer needs a `signals` array, it automatically track each signal.

  _Before_:

  ```dart
  final effect = createEffect(() {
    print('The counter is now ${counter.value}');
  }, signals: [counter]);
  ```

  _Now_:

  ```dart
  final disposeFn = createEffect((disposeFn) {
    print('The counter is now ${counter.value}');
  })
  ```

- **BREAKING CHANGE**: The `createEffect` method no longer returns an `Effect`, you cannot pause or resume it anymore.
  Instead it returns a `Dispose` callback which you can call when you want to stop it.
  You can also dispose an effect from the inside of the callback.
- **BREAKING CHANGE**: The `fireImmediately` field on effects has been removed. Now an effect runs immediately by default.
- **FEAT**: Add `observe` method on `Signal`. Use it to easily observe the previous and current value instead of creating an effect.
  ```dart
  final count = createSignal(0);
  final disposeFn = count.observe((previousValue, value) {
    print('The counter changed from $previousValue to $value');
  }, fireImmediately: true);
  ```
- **FEAT**: Add `until` method on `Signal`. It returns a future that completes when the condition evalutes to true and it
  returns the current signal value.
  ```dart
  final count = createSignal(0);
  // wait until the count is greater than 5
  final value = await count.until((value) => value > 5);
  ```
- **FEAT**: Add `untilReady` method on `Resource`. Now you can wait until the resource is ready.
  ```dart
  final resource = createResource(..);
  final data = await resource.untilReady();
  ```
- **FEAT**: The `Resource` now accepts `ResourceOptions`. You can customize the `lazy` value of the resource (defaults to true),
  if you want your resource to resolve immediately.
- **CHORE**: `ResourceValue` has been renamed into `ResourceState`. Now you can get the state of the resource with the `state` getter.

## 0.3.0

- **BUGFIX**: Listening to the `source` of a Resource was not stopped when the `source` disposed.
- **BUGFIX**: A `Resource` would not perform the asynchronous operation until someone called the `fetch` method, typically the `ResourceBuilder` widget. This did not apply to the `stream` which was listened to when the resource was created. Now the behaviour has been merged and the `fetch` method has been renamed into `resolve`.
- **CHORE**: Renamed `ReadableSignal` into `ReadSignal`.
- **CHORE**: Renamed the `readable` method of a `Signal` into `toReadSignal()`

## 0.2.4

- Add assert to resource `fetch` method to prevent multiple fetches of the same resource.

## 0.2.3

- The `select` method of a signal now can take a custom `options` parameter to customize its behaviour.
- Fixed an invalid assert in the `ResourceBuilder` widget that happens for resources without a fetcher.

## 0.2.2

- `createResource` now accepts a `stream` and can be used to wrap a Stream and correctly handle its state.

## 0.2.1

- Get a signal value with `signalName()`.

## 0.2.0+1

- Add documentation link inside the pubspec

## 0.2.0

- Documentation improvements
- Refactor Resource, now the `createResource` method takes only 1 generic, the type of the future result.
  ```dart
  // before
  final resource = createResource<SourceValueType, FetcherValueType>(fetcher: fetcher, source: source);
  // now
  final resource = createResource<FetcherValueType>(fetcher: fetcher, source: source); // the FetcherValueType can be inferred by Dart >=2.18.0, so you can omit it
  ```

## 0.1.2

- Add official documentation link
- Fix typo in fireImmediately argument name

## 0.1.1

- Set the minimum Dart SDK version to `2.18`.

## 0.1.0+6

- Update Readme

## 0.1.0+5

- Add code coverage

## 0.1.0+4

- Fix typo in README

## 0.1.0+3

- Decrease minimum Dart version to 2.17.0

## 0.1.0+2

- Remove unused import

## 0.1.0+1

- Fix typos on links

## 0.1.0

- Initial version.
