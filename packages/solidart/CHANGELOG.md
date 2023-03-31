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
