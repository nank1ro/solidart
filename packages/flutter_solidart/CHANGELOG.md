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
