## 2.8.2

- **REFACTOR**: Improve the Solidart DevTools extension by giving any signal an id and omit overriding the same signal by name.

## 2.8.1

- **FIX**: Expose `until` method for `Computed`.

## 2.8.0

- **REFACTOR**: Deprecate `maybeOn` and `on` methods of `ResourceState`. Use `maybeWhen` and `when` instead.

## 2.7.1

- **REFACTOR**: Rename `update` to `shouldUpdate` in `ReadableSignal`.

## 2.7.0

- **FEAT**: Add `then` extension method to `FutureOr`. This allows you to use the `then` method on both `Future` and `FutureOr` values seamlessly. Mainly needed to simplify the usage of `ReadableSignal.until` and `Resource.untilReady` methods.
  ```dart
  final count = Signal(10);
  count.until((value) => value > 5).then((value) {
    print('The count is now greater than 5: $value');
  });
  ```

## 2.6.1

- **FIX**: Fix auto disposal of `Computed` which happened even if `autoDispose` was set to false.

## 2.6.0

- **REFACTOR**: Make auto disposal synchronous.

## 2.5.0

- **FEAT**: Add `run` method to `Computed` to manually trigger an update of its value.
- **FEAT**: Add `run` method to `Effect` to manually re-run the effect.
- **CHORE**: Detect if `Effect` didn't track any reactive value and throw an `EffectWithoutDependenciesError`.

## 2.4.1

- **FIX**: `Signal.lazy` which caused an exception.

## 2.4.0

- **FEAT**: Add `Debouncer` utility class to easily debounce operations and `debounceDelay` to `Resource` to debounce source changes if they fire very often.

## 2.3.0

- **FEAT**: Allow extending signal, computed, resource, list-signal, set-signal and map-signal.

## 2.2.0

- **FEAT**: Add `timeout` parameter to `Signal.until` method to specify a timeout duration. If the condition is not met within the specified duration, the returned future will complete with a `TimeoutException`.

## 2.1.1+1

- **CHORE**: Update `README.md` with new contributors.

## 2.1.1

- **CHORE**: Bump the `alien_signals` dependency to `^0.5.1` for slight performance improvements (thanks to @medz).

## 2.1.0

- **REFACTOR**: Update `alien_signals` dependency from `^0.2.1` to `^0.4.3` with significant performance improvements (thanks to @medz).
- **REFACTOR**: Replace custom reactive node implementations with `alien.ReactiveNode` for better compatibility and performance (thanks to @medz).
- **REFACTOR**: Simplify signal, computed and effect implementations by leveraging new `alien_signals` API (thanks to @medz).
- **PERFORMANCE**: Improve performance by removing redundant tracking operations in the reactive system  (thanks to @medz).
- **FIX**: Add proper cleanup for disposed nodes to prevent memory leaks  (thanks to @medz).
- **FIX**: Fix potential memory leaks in auto-dispose scenarios (thanks to @medz).
- **FIX**: Clear queued flag when running effects in `ReactiveSystem` to ensure proper effect execution (thanks to @medz).
- **CHORE**: Reorder dev_dependencies in pubspec.yaml for improved organization and readability (thanks to @medz).

## 2.0.1

- **FIX**: DevTools extension not working.

## 2.0.0

- **CHORE**: Improve the performance by using `alien_signals` for the reactive system.
- **FEAT**: Expose `untracked`.
- **REFACTOR**: Updated the reactive system from scratch, improving the performances.
- **BREAKING CHANGE**: Remove `set` and `call` methods from Signals (Use an extension to have them back).
- **FEAT**: Add `useRefreshing` to `Resource` to decide whether to update the current state with `isRefreshing` (defaults to true). If you set it to false, when refreshing, the resource will go directly to the loading state.
- **FEAT**: Add `Signal.lazy` to allow the creation of a signal without an initial value. Be aware, the signal will throw an error if you try to read its value before it has been initialized.
- **CHORE**: Remove deprecated `createSignal`, `createComputed`, `createEffect` and `createResource` helpers.
- **CHORE**: Remove `SignalOptions` and `ResourceOptions` classes.
- **FEAT**: Add `batch` function to execute a callback that will not side-effect until its top-most batch is completed. See docs [here](https://solidart.mariuti.com/learning/batch)
- **CHORE**: Add `trackInDevTools` to `SignalOptions` and `ResourceOptions` to disable the DevTools tracking for specific signals and resources, defaults to `SolidartConfig.devToolsEnabled`.

## 2.0.0-dev.6

- **FEAT**: Expose `untracked`.

## 2.0.0-dev.5

- **CHORE**: Improve the performance

## 2.0.0-dev.4

- **REFACTOR**: Updated the reactive system from scratch, improving the performances.
- **BREAKING CHANGE**: Remove `set` and `call` methods from Signals (Use an extension to have them back).
- **FEAT**: Add `useRefreshing` to `Resource` to decide whether to update the current state with `isRefreshing` (defaults to true). If you set it to false, when refreshing, the resource will go directly to the loading state.

## 2.0.0-dev.3

- **FEAT**: Add `Signal.lazy` to allow the creation of a signal without an initial value. Be aware, the signal will throw an error if you try to read its value before it has been initialized.

## 2.0.0-dev.2

- **CHORE**: Remove deprecated `createSignal`, `createComputed`, `createEffect` and `createResource` helpers.
- **CHORE**: Remove `SignalOptions` and `ResourceOptions` classes.

## 2.0.0-dev.1

- **FEAT**: Add `batch` function to execute a callback that will not side-effect until its top-most batch is completed. See docs [here](https://docs.page/nank1ro/solidart~dev/learning/batch)
- **CHORE**: Add `trackInDevTools` to `SignalOptions` and `ResourceOptions` to disable the DevTools tracking for specific signals and resources, defaults to `SolidartConfig.devToolsEnabled`.

## 1.5.4

- **CHORE**: Add `devToolsEnabled` option to manually disable the DevTools extension that defaults to `kDebugMode`

## 1.5.3

- **BUGFIX**: Fix an auto dispose issue of Signals that have some active observations.

## 1.5.2

- **BUGFIX**: Fix DevTools extension with null signal name.

## 1.5.1

- **CHORE**: Upload DevTools extension to pub.dev

## 1.5.0

- **FEAT**: Add DevTools extension to solidart.

## 1.4.1

- **BUGFIX**: The method `didUpdateSignal` of `SolidartObserver` was not triggered for collections.

## 1.4.0

- **FEAT**: Create `SolidartConfig` which you can use to customize the `autoDispose` of all the tracking system and and `observers`.
- **BUGFIX**: Removed the internal `ResourceUnresolved` state so you can easily use the `ResourceState` sealed class.

## 1.3.0

- **FEAT**: Automatic disposal, [see the docs here](https://docs.page/nank1ro/solidart~dev/advanced/automatic-disposal)

## 1.2.2

- **BUGFIX**: Fix the `update` method of a `Resource` that triggered `reportObserved`.

## 1.2.1

- **BUGFIX**: Fix the `updateValue` method of a `Signal` that triggered `reportObserved`. (thanks to @9dan)

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
- **CHORE**: Deprecate `createSignal`, `createComputed`, `createEffect` and `createResource`

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
- **FEAT**: Add `firstWhere` method on `Signal`. It returns a future that completes when the condition evaluates to true and it returns the current signal value.
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
- **FEAT**: Add `until` method on `Signal`. It returns a future that completes when the condition evaluates to true and it
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
