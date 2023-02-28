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
            create: (_) => const NameProvider('Ale'),
            // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
            dispose: (context, provider) => provider.dispose(),
          ),
          SolidProvider<NumberProvider>(
            create: (_) => const NumberProvider(1),
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
