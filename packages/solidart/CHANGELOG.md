## 1.2.0

- **FEAT**: Add 3 new signals: `ListSignal`, `SetSignal` and `MapSignal`. Now you can easily be notified of every change of a list, set or map.
   _Before_:

  ```dart
  final list = Signal([1, 2]);
  // this doesn't work
  list.add(3);
  // instead you have to provide a new list instance
  list.value = [...list, 3];
  ```

  _Now_:

  ```dart
  final list = ListSignal([1, 2]);
  // this now works as expected
  list.add(3);
  ```

- **CHORE**: Rename the `firstWhere` method of a `ReadSignal` into `until`
- **CHORE**: Rename the `firstWhereReady` method of a `Resource` into `untilReady`
- **CHORE**: Rename the `update` method of a `Signal` into `updateValue`

## 1.1.0

- **BUGFIX**: Fix a bug in the `Resource` where the stream subscription was not disposed correctly

## 1.0.1

Improve `copyWith` methods of `ResourceReady` and `ResourceError`

## 1.0.0+4

Fix the pub.dev pub points.

## 1.0.0+3

Fix the pub.dev pub points.

## 1.0.0+2

Fix the pub.dev pub points.

## 1.0.0+1

Fix the pub.dev pub points.

## 1.0.0

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

- **BREAKING CHANGE**: The `fireImmediately` field on effects has been removed. Now an effect runs immediately by default.
- **FEAT**: Add `observe` method on `Signal`. Use it to easily observe the previous and current value instead of creating an effect.
  ```dart
  final count = createSignal(0);
  final disposeFn = count.observe((previousValue, value) {
    print('The counter changed from $previousValue to $value');
  }, fireImmediately: true);
  ```
- **FEAT**: Add `firstWhere` method on `Signal`. It returns a future that completes when the condition evalutes to true and it returns the current signal value.
  ```dart
  final count = createSignal(0);
  // wait until the count is greater than 5
  final value = await count.firstWhere((value) => value > 5);
  ```
- **FEAT**: Add `firstWhereReady` method on `Resource`. Now you can wait until the resource is ready.
  ```dart
  final resource = createResource(..);
  final data = await resource.firstWhereReady();
  ```
- **FEAT**: The `Resource` now accepts `ResourceOptions`. You can customize the `lazy` value of the resource (defaults to true), if you want your resource to resolve immediately.
- **CHORE**: `ResourceValue` has been renamed into `ResourceState`. Now you can get the state of the resource with the `state` getter.
- **CHORE**: Move `refreshing` from `ResourceWidgetBuilder` into the `ResourceState`. (thanks to @manuel-plavsic)
- **FEAT**: Add `hasPreviousValue` getter to `ReadSignal`. (thanks to @manuel-plavsic)
- **FEAT** Before, only the `fetcher` reacted to the `source`.
Now also the `stream` reacts to the `source` changes by subscribing again to the stream.
In addition, the `stream` parameter of the Resource has been changed from `Stream` into a `Stream Function()` in order to be able to listen to a new stream if it changed.
- **FEAT**: Add the `select` method on the `Resource` class.
The `select` function allows filtering the `Resource`'s data by reading only the properties that you care about.
The advantage is that you keep handling the loading and error states.
- **FEAT**: Make the `Resource` to auto-resolve when accessing its `state`.
- **CHORE**: The `refetch` method of a `Resource` has been renamed to `refresh`.
- **FEAT**: You can decide whether to use `createSignal()` or directly the `Signal()` constructor, now the're equivalent. The same applies to all the other `create` functions.

## 1.0.0-dev8

- **FEAT**: Add the select method on the Resource class.
The select function allows filtering the Resource's data by reading only the properties that you care about.
The advantage is that you keep handling the loading and error states.
- **FEAT**: Make the Resource to auto-resolve when accessing its state

## 1.0.0-dev7

- **CHORE**: `createComputed` now returns a `Computed` class instead of a `ReadSignal`.

## 1.0.0-dev6

- **FEAT** Before, only the `fetcher` reacted to the `source`.
Now also the `stream` reacts to the `source` changes by subscribing again to the stream.
In addition, the `stream` parameter of the Resource has been changed from `Stream` into a `Stream Function()` in order to be able to listen to a new stream if it changed

## 1.0.0-dev5

- **BUGFIX** Refactor the core of the library in order to fix issues with `previousValue` and `hasPreviousValue` of `Computed` and simplify the logic.

## 1.0.0-dev4

- Move `refreshing` from `ResourceWidgetBuilder` into the `ResourceState`. (thanks to @manuel-plavsic)
- Add `hasPreviousValue` getter to `ReadSignal`. (thanks to @manuel-plavsic)

## 1.0.0-dev3

- Deprecate `value` getter in the `Resource`. Use `state` instead.
- Remove `where` method from `ReadSignal`.

## 1.0.0-dev2

- Rename `until` into `firstWhere`
- Rename `untilReady` into `firstWhereReady`
- **FEAT**: add `where` method to `Signal`. It returns a new `ReadSignal` with the values filtered by `condition`.
  Use it to filter the value of another signal, e.g.:

  ```dart
  final loggedInUser = user.where((value) => value != null);
  ```

  The initial value may be null because a `Signal` must always start with an initial value.
  The following values will always satisfy the condition.
  The returned `ReadSignal` will automatically dispose when the parent signal disposes.

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
