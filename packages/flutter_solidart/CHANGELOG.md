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
