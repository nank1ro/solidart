[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nank1ro/solidart)](https://gitHub.com/nank1ro/solidart/stargazers/)
[![Coverage](https://codecov.io/gh/nank1ro/solidart/branch/main/graph/badge.svg?token=HvJYtaixiW)](https://codecov.io/gh/nank1ro/solidart)
[![GitHub issues](https://img.shields.io/github/issues/nank1ro/solidart)](https://github.com/nank1ro/solidart/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/nank1ro/solidart.svg)](https://gitHub.com/nank1ro/solidart/pull/)
[![solidart Pub Version (including pre-releases)](https://img.shields.io/pub/v/solidart?include_prereleases)](https://pub.dev/packages/solidart)

# A simple state-management library inspired by SolidJS.

The objectives of this project are:

1. Being simple and easy to learn
2. Do not go against the framework (e.g. Flutter) with weird workarounds.
3. Do not have a single global state, but put multiple states only in the most appropriate places

## Learning

For an comprehensive documentation go to [The Official Documentation](https://docs.page/nank1ro/solidart)

There are 3 main concepts you should be aware:

1. [Signals](#signals)
2. [Effects](#effects)
3. [Resources](#resources)

### Signals

Signals are the cornerstone of reactivity in _solidart_. They contain values that change over time; when you change a signal's value, it automatically updates anything that uses it.

To create a signal, you have to use the `createSignal` method:

```dart
final counter = createSignal(0);
```

The argument passed to the create call is the initial value, and the return value is the signal.

```dart
// Retrieve the current counter value
print(counter.value); // prints 0
// Increment the counter value
counter.value++;
```

### Effects

Signals are trackable values, but they are only one half of the equation. To complement those are observers that can be updated by those trackable values. An effect is one such observer; it runs a side effect that depends on signals.

An effect can be created by using `createEffect`.
The effect subscribes to any signal provided in the `signals` array and reruns when any of them change.

So let's create an Effect that reruns whenever `counter` changes:

```dart
createEffect(() {
    print("The count is now ${counter.value}");
}, signals: [counter]);
```

### Resources

Resources are special Signals designed specifically to handle Async loading. Their purpose is wrap async values in a way that makes them easy to interact with.

Resources can be driven by a `source` signal that provides the query to an async data `fetcher` function that returns a `Future`.

The contents of the `fetcher` function can be anything. You can hit typical REST endpoints or GraphQL or anything that generates a future. Resources are not opinionated on the means of loading the data, only that they are driven by futures.

Let's create a Resource:

```dart
// The source
final userId = createSignal(1);

// The fetcher
Future<String> fetchUser() async {
    final response = await http.get(
      Uri.parse('https://swapi.dev/api/people/${userId.value}/'),
    );
    return response.body;
}

// The resource
final user = createResource(fetcher: fetchUser, source: userId);
```
