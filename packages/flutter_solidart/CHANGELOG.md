## 2.4.1

- **FIX**: `SignalBuilder` not working with inherited widgets. This is just a temporary patch, a better solution needs to be found, because inherited widgets tracked inside the builder won't react.

## 2.4.0

- **CHORE**: Detect if `SignalBuilder` didn't track any reactive value and throw a `SignalBuilderWithoutDependenciesError`.

### Changes from solidart

- **FEAT**: Add `run` method to `Computed` to manually trigger an update of its value.
- **FEAT**: Add `run` method to `Effect` to manually re-run the effect.
- **CHORE**: Detect if `Effect` didn't track any reactive value and throw an `EffectWithoutDependenciesError` exception.

## 2.3.3

- **FIX**: Bump the `solidart` dependency to `^2.4.1`.

## 2.3.2

- **FIX**: `Signal.lazy` which caused an exception.
- **CHORE**: Improve `SignalBuilder` error handling and rebuilding.

## 2.3.1

- **FIX**: `SignalBuilder` rebuilded twice when a signal changed, added unit test to prevent this from happening again.

## 2.3.0

### Changes from solidart

- **FEAT**: Add `Debouncer` utility class to easily debounce operations and `debounceDelay` to `Resource` to debounce source changes if they fire very often.

## 2.2.0

### Changes from solidart

- **FEAT**: Allow extending signal, computed, resource, list-signal, set-signal and map-signal.

## 2.1.0

### Changes from solidart

- **FEAT**: Add `timeout` parameter to `Signal.until` method to specify a timeout duration. If the condition is not met within the specified duration, the returned future will complete with a `TimeoutException`.

## 2.0.1

- **CHORE**: Update the `solidart` dependency to `^2.1.0`.

### Changes from solidart

- **REFACTOR**: Update `alien_signals` dependency from `^0.2.1` to `^0.4.3` with significant performance improvements (thanks to @medz).
- **REFACTOR**: Replace custom reactive node implementations with `alien.ReactiveNode` for better compatibility and performance (thanks to @medz).
- **REFACTOR**: Simplify signal, computed and effect implementations by leveraging new `alien_signals` API (thanks to @medz).
- **PERFORMANCE**: Improve performance by removing redundant tracking operations in the reactive system  (thanks to @medz).
- **FIX**: Add proper cleanup for disposed nodes to prevent memory leaks  (thanks to @medz).
- **FIX**: Fix potential memory leaks in auto-dispose scenarios (thanks to @medz).
- **FIX**: Clear queued flag when running effects in `ReactiveSystem` to ensure proper effect execution (thanks to @medz).
- **CHORE**: Reorder dev_dependencies in pubspec.yaml for improved organization and readability (thanks to @medz).

## 2.0.0

- **BREAKING CHANGE**: Remove `Solid` and `Provider`s, use [disco](https://pub.dev/packages/disco) instead.
- **FEAT**: The `SignalBuilder` widget now automatically tracks the `Signal`s used in the `builder` function allowing you to react to N signals at the same time. See the [migration guide](https://docs.page/nank1ro/solidart~dev/migration).
- **BREAKING CHANGE**: Removed `DualSignalBuilder` and `TripleSignalBuilder` in favor of `SignalBuilder`.
- **BREAKING CHANGE**: Removed `ResourceBuilder` in favor of `SignalBuilder`. See the [migration guide](https://docs.page/nank1ro/solidart~dev/migration).

### Changes from solidart

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

## 2.0.0-dev.3

- **BREAKING CHANGE**: Remove `Solid` and `Provider`s, use [disco](https://pub.dev/packages/disco) instead.

### Changes from solidart

- **REFACTOR**: Updated the reactive system from scratch, improving the performances.
- **BREAKING CHANGE**: Remove `set` and `call` methods from Signals (Use an extension to have them back).
- **FEAT**: Add `useRefreshing` to `Resource` to decide whether to update the current state with `isRefreshing` (defaults to true). If you set it to false, when refreshing, the resource will go directly to the loading state.

## 2.0.0-dev.2

### Changes from solidart

- *CHORE*: Remove deprecated `createSignal`, `createComputed`, `createEffect` and `createResource` helpers.
- *CHORE*: Remove `SignalOptions` and `ResourceOptions` classes.

## 2.0.0-dev.1

- **FEAT**: The `SignalBuilder` widget now automatically tracks the `Signal`s used in the `builder` function allowing you to react to N signals at the same time. See the [migration guide](https://docs.page/nank1ro/solidart~dev/migration).
- **BREAKING CHANGE**: Removed `DualSignalBuilder` and `TripleSignalBuilder` in favor of `SignalBuilder`.
- **BREAKING CHANGE**: Removed `ResourceBuilder` in favor of `SignalBuilder`. See the [migration guide](https://docs.page/nank1ro/solidart~dev/migration).
- **CHORE**: Improved `Solid` widget performance by more than 3000% in finding ancestor providers.

### Changes from solidart

- **FEAT**: Add `batch` function to execute a callback that will not side-effect until its top-most batch is completed. See docs [here](https://docs.page/nank1ro/solidart~dev/learning/batch)
- **CHORE**: Add `trackInDevTools` to `SignalOptions` and `ResourceOptions` to disable the DevTools tracking for specific signals and resources, defaults to `SolidartConfig.devToolsEnabled`.

## 1.7.1

- Update dependencies

## 1.7.0

### Changes from solidart

- **FEAT**: Add DevTools extension to solidart.

## 1.6.1

### Changes from solidart

- **BUGFIX**: The method `didUpdateSignal` of `SolidartObserver` was not triggered for collections.

## 1.6.0

### Changes from solidart

- **FEAT**: Create `SolidartConfig` which you can use to customize the `autoDispose` of all the tracking system and and `observers`.
- **BUGFIX**: Removed the internal `ResourceUnresolved` state so you can easily use the `ResourceState` sealed class.

## 1.5.0

### Changes from solidart

- **FEAT**: Automatic disposal, [see the docs here](https://docs.page/nank1ro/solidart~dev/advanced/automatic-disposal)

## 1.4.3

### Changes from solidart

- **BUGFIX**: Fix the `update` method of a `Resource` that triggered `reportObserved`.

## 1.4.2

Update solidart version

## 1.4.1

### Changes from solidart

- **BUGFIX**: Fix the `updateValue` method of a `Signal` that triggered `reportObserved`. (thanks to @9dan)

## 1.4.0

- **CHORE**: Rename `SolidProvider` into `Provider`.
- **REFACTOR**: Remove `SolidSignal` in favor of `Provider`.

## 1.3.0

### Changes from solidart

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

## 1.2.0

- **FEAT**: Add the method `maybeGet()` to the `Solid` widget to get a provider. If the provider can't be found, returns `null` instead of throwing like `get()` does

## 1.1.0

### Changes from solidart

- **BUGFIX**: Fix a bug in the `Resource` where the stream subscription was not disposed correctly

## 1.0.1

### Changes from solidart

- **CHORE** Improve `copyWith` methods of `ResourceReady` and `ResourceError`

## 1.0.0

The core of the library has been rewritten in order to support automatic dependency tracking like SolidJS.

- The `Show` widget now takes a functions that returns a `bool`.
  You can easily convert any type to `bool`, for example:
  ```dart
  final count = createSignal(0);

  @override
  Widget build(BuildContext context) {
    return Show(
      when: () => count() > 5,
      builder: (context) => const Text('Count is greater than 5'),
      fallback: (context) => const Text('Count is lower than 6'),
    );
  }
  ```
- Converting a `ValueNotifier` into a `Signal` now uses the `equals` comparator to keep the consistency.
- Rename `resource` parameter of `ResourceWidgetBuilder` into `resourceState`. (thanks to @manuel-plavsic)
- **FEAT** Allow multiple providers of the same type by specifying an `id`entifier.

  ### Provider declaration:
  ```dart
  SolidProvider<NumberProvider>(
    create: () => const NumberProvider(1),
    id: 1,
  ),
  SolidProvider<NumberProvider>(
    create: () => const NumberProvider(10),
    id: 2,
  ),
  ```

  ### Access a specific provider
  ```dart
  final numberProvider1 = context.get<NumberProvider>(1);
  final numberProvider2 = context.get<NumberProvider>(2);
  ```

- **BREAKING CHANGE** Removed the `signals` map from `Solid`, now to provide signals to descendants
  use `SolidSignal` inside providers:

  _Before_:

  ```dart
  Solid(
    signals: {
      SignalId.themeMode: () => createSignal<ThemeMode>(ThemeMode.light),
    },
  ),
  ```

  _Now_:

  ```dart
  Solid(
    providers: [
      SolidSignal<Signal<ThemeMode>>(create: () => createSignal(ThemeMode.light)),
    ],
  ),
  ```
- **FEAT** You can access a specific `Signal` without specifing an `id`entifier, for example:
  ```dart
  // to get the signal
  context.get<Signal<ThemeMode>>();
  // to observe the signal's value
  context.observe<ThemeMode>()
  ```
  > NOTICE: If you have multiple signals of the same type, you must specify a different `id` for each one.
- **FEAT**: Now you can get any instance of (any subclass of) the provider type.
- **FEAT**: The `Solid` widget now acceps a `builder` method that provides a descendant context.
- **CHORE**: The `ResourceBuilder` no longer resolves the resource, because now the `Resource` knows when to resolve automatically.

### Changes from solidart

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

## 1.0.0-dev903

- **FEAT**: The `Solid` widget now acceps a `builder` method that provides a descendant context.
- **CHORE**: The `ResourceBuilder` no longer resolves the resource, because now the `Resource` knows when to resolve automatically.

### Changes from solidart

- **FEAT**: Add the select method on the Resource class.
The select function allows filtering the Resource's data by reading only the properties that you care about.
The advantage is that you keep handling the loading and error states.
- **FEAT**: Make the Resource to auto-resolve when accessing its state

## 1.0.0-dev902

- **CHORE**: Deprecate the value setter in the `Resource` in favor of the state setter

## 1.0.0-dev901

- **FEAT**: Now you can get any instance of (any subclass of) the provider type.

## 1.0.0-dev9

- **FIX**: A small fix of the `Solid` widget now allows to correctly retrieve a `Computed` signal

### Changes from solidart

- **CHORE**: `createComputed` now returns a `Computed` class instead of a `ReadSignal`.

## 1.0.0-dev8

- **FEAT** Allow multiple providers of the same type by specifying an `id`entifier.

  ### Provider declaration:
  ```dart
  SolidProvider<NumberProvider>(
    create: () => const NumberProvider(1),
    id: 1,
  ),
  SolidProvider<NumberProvider>(
    create: () => const NumberProvider(10),
    id: 2,
  ),
  ```

  ### Access a specific provider
  ```dart
  final numberProvider1 = context.get<NumberProvider>(1);
  final numberProvider2 = context.get<NumberProvider>(2);
  ```

- **BREAKING CHANGE** Removed the `signals` map from `Solid`, now to provide signals to descendants
  use `SolidSignal` inside providers:

  _Before_:

  ```dart
  Solid(
    signals: {
      SignalId.themeMode: () => createSignal<ThemeMode>(ThemeMode.light),
    },
  ),
  ```

  _Now_:

  ```dart
  Solid(
    providers: [
      SolidSignal<Signal<ThemeMode>>(create: () => createSignal(ThemeMode.light)),
    ],
  ),
  ```

- **FEAT** You can access a specific Signal without specifing an `id`entifier, for example:
  ```dart
  // to get the signal
  context.get<Signal<ThemeMode>>();
  // to observe the signal's value
  context.observe<ThemeMode>()
  ```
  > NOTICE: If you have multiple signals of the same type, you must specify a different `id` for each one.

## 1.0.0-dev7

### Changes from solidart

- **FEAT** Before, only the `fetcher` reacted to the `source`.
Now also the `stream` reacts to the `source` changes by subscribing again to the stream.
In addition, the `stream` parameter of the Resource has been changed from `Stream` into a `Stream Function()` in order to be able to listen to a new stream if it changed

## 1.0.0-dev6

### Changes from solidart

- **BUGFIX** Refactor the core of the library in order to fix issues with `previousValue` and `hasPreviousValue` of `Computed` and simplify the logic.

## 1.0.0-dev5

- Rename `resource` parameter of `ResourceWidgetBuilder` into `resourceState`. (thanks to @manuel-plavsic)

### Changes from solidart

- Move `refreshing` from `ResourceWidgetBuilder` into the `ResourceState`. (thanks to @manuel-plavsic)
- Add `hasPreviousValue` getter to `ReadSignal`. (thanks to @manuel-plavsic)

## 1.0.0-dev4

- Converting a `ValueNotifier` into a `Signal` now uses the `equals` comparator to keep the consistency.

### Changes from solidart

Deprecate `value` getter in the `Resource`. Use `state` instead.

## 1.0.0-dev3

Add `SolidSignalOptions` and `SolidResourceOptions` for signals and resources provided through the Solid widget.
With this field you can customize the `autoDispose` of each Solid signal individually. (Defaults to true).

### Changes from solidart

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

## 1.0.0-dev2

The `Show` widget now takes a functions that returns a `bool`.
You can easily convert any type to `bool`, for example:

```dart
final count = createSignal(0);

@override
Widget build(BuildContext context) {
  return Show(
    when: () => count() > 5,
    builder: (context) => const Text('Count is greater than 5'),
    fallback: (context) => const Text('Count is lower than 6'),
  );
}
```

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
- **FEAT**: Add `toValueNotifier()` extension to `Signal` to easily convert it to a `ValueNotifier`.
- **FEAT**: Add `toSignal()` extension to `ValueNotifier` to easily convert it to a `Signal`.

## 0.4.2

- **BUGFIX**: The `Show` widget now can work again with a `ReadSignal`.

## 0.4.1

- **CHORE**: The `ResourceBuilder` now correctly handles a different `Resource` when the widget is updated.

## 0.4.0

- **BUGFIX**: Listening to the `source` of a Resource was not stopped when the `source` disposed.
- **BUGFIX**: A `Resource` would not perform the asynchronous operation until someone called the `fetch` method, typically the `ResourceBuilder` widget. This did not apply to the `stream` which was listened to when the resource was created. Now the behaviour has been merged and the `fetch` method has been renamed into `resolve`.
- **CHORE**: Renamed `ReadableSignal` into `ReadSignal`.
- **CHORE**: Renamed the `readable` method of a `Signal` into `toReadSignal()`

## 0.3.3

- Add `update` extension on `BuildContext`.
  It's a convenience method to update a `Signal` value.

  You can use it to update a signal value, e.g:

  ```dart
  context.update<int>('counter', (value) => value * 2);
  ```

  This is equal to:

  ```dart
  // retrieve the signal
  final signal = context.get<Signal<int>>('counter');
  // update the signal
  signal.update((value) => value * 2);
  ```

  but shorter when you don't need the signal for anything else.

## 0.3.2

- Add assert to resource `fetch` method to prevent multiple fetches of the same resource.
- Fix `ResourceBuilder` that fetched the resource every time even if the resource was already resolved.

## 0.3.1

- The `select` method of a signal now can take a custom `options` parameter to customize its behaviour.
- Fixed an invalid assert in the `ResourceBuilder` widget that happens for resources without a fetcher.

## 0.3.0

- Now Solid can deal also with `SolidProviders`. You no longer need an external dependency injector library.
  I decided to put some boundaries and stop suggesting any external dependency injector library.
  This choice is due to the fact that external libraries in turn provide state management and the user is more likely to mistakenly use solidart.
  I simplified the usage of InheritedWidgets with a very nice API:

  ### Declare providers

  ```dart
  Solid(
        providers: [
          SolidProvider<NameProvider>(
            create: () => const NameProvider('Ale'),
            // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
            dispose: (provider) => provider.dispose(),
          ),
          SolidProvider<NumberProvider>(
            create: () => const NumberProvider(1),
            // Do not create the provider lazily, but immediately
            lazy: false,
          ),
        ],
        child: const SomeChildThatNeedsProviders(),
    )
  ```

  ### Retrieve providers

  ```dart
  final nameProvider = context.get<NameProvider>();
  final numberProvider = context.get<NumberProvider>();
  ```

  ### Provide providers to modals (dialogs, bottomsheets)

  ```dart
    return showDialog(
      context: context,
      builder: (dialogContext) => Solid.value(
        // pass a context that has access to providers
        context: context,
        // pass the list of provider [Type]s
        providerTypes: const [NameProvider],
        child: Dialog(
          child: Builder(builder: (innerContext) {
            // retrieve the provider with the innerContext
            final nameProvider = innerContext.get<NameProvider>();
            return SizedBox.square(
              dimension: 100,
              child: Center(
                child: Text('name: ${nameProvider.name}'),
              ),
            );
          }),
        ),
      ),
    );
  ```

  > You cannot provide multiple providers of the same type in the same Solid widget.

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

## 0.1.4

- Add official documentation link
- Fix typo in fireImmediately argument name

## 0.1.3

- Now `Solid.value` takes a list of [signalIds] and a [BuildContext]. You don't need anymore to get the signal first and pass it to `Solid.value`.
- Set the minimum Dart SDK version to `2.18`.

## 0.1.2+1

- Update Readme

## 0.1.2

- Add code coverage

## 0.1.1

- Implement Solid.value to be able to pass Signals to modals

## 0.1.0+4

- Add links to examples

## 0.1.0+3

- Specify the type of resource to the ResourceBuilder

## 0.1.0+2

- Decrease minimum Dart version to 2.17.0

## 0.1.0+1

- Fix home page link

## 0.1.0

- Initial version
