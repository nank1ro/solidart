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
