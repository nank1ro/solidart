[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nank1ro/solidart)](https://gitHub.com/nank1ro/solidart/stargazers/)
[![Coverage](https://codecov.io/gh/nank1ro/solidart/branch/main/graph/badge.svg?token=HvJYtaixiW)](https://codecov.io/gh/nank1ro/solidart)
[![GitHub issues](https://img.shields.io/github/issues/nank1ro/solidart)](https://github.com/nank1ro/solidart/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/nank1ro/solidart.svg)](https://gitHub.com/nank1ro/solidart/pull/)
[![solidart Pub Version (including pre-releases)](https://img.shields.io/pub/v/solidart?include_prereleases)](https://pub.dev/packages/solidart)
[![](https://dcbadge.vercel.app/api/server/2JBzeeQShh)](https://discord.gg/2JBzeeQShh)

# A simple state-management library inspired by SolidJS.

The objectives of this project are:

1. Being simple and easy to learn
2. Fits well with the framework's good practices
3. Do not have a single global state, but multiple states only in the most appropriate places
4. No code generation

## Learning

For a comprehensive and updated documentation go to [The Official Documentation](https://docs.page/nank1ro/solidart)

There are 4 main concepts you should be aware:

1. [Signals](#signals)
2. [Effects](#effects)
3. [Computed](#computed)
4. [Resources](#resources)

### Signals

Signals are the cornerstone of reactivity in _solidart_. They contain values that change over time; when you change a signal's value, it automatically updates anything that uses it.

To create a signal, you have to use the `Signal` class:

```dart
final counter = Signal(0);
```

The argument passed to the class is the initial value, and the return value is the signal.


To retrieve the current value, you can use:
```dart
print(counter.value); // prints 0
// or
print(counter());
```

To change the value, you can use:
```dart
// Increments by 1
counter.value++; 
// Set the value to 2
counter.value = 2;
// equivalent to
counter.set(2);
// Update the value based on the current value
counter.updateValue((value) => value * 2);
```

### Effects

Signals are trackable values, but they are only one half of the equation. To complement those are observers that can be updated by those trackable values. An effect is one such observer; it runs a side effect that depends on signals.

An effect can be created by using the `Effect` class.
The effect automatically subscribes to any signal and reruns when any of them change.
So let's create an Effect that reruns whenever `counter` changes:

```dart
final disposeFn = Effect((_) {
    print("The count is now ${counter.value}");
});
```

### Computed

A computed signal is a signal that depends on other signals.
To create a computed signal, you have to use the `Computed` class.

A `Computed` automatically subscribes to any signal provided and reruns when any of them change.

```dart
final name = Signal('John');
final lastName = Signal('Doe');
final fullName = Computed(() => '${name.value} ${lastName.value}');
print(fullName()); // prints "John Doe"

// Update the name
name.set('Jane');
print(fullName()); // prints "Jane Doe"
```

### Resources

Resources are special Signals designed specifically to handle Async loading. Their purpose is wrap async values in a way that makes them easy to interact with.

Resources can be driven by a `source` signal that provides the query to an async data `fetcher` function that returns a `Future`.

The contents of the `fetcher` function can be anything. You can hit typical REST endpoints or GraphQL or anything that generates a future. Resources are not opinionated on the means of loading the data, only that they are driven by futures.

Let's create a Resource:

```dart
// The source
final userId = Signal(1);

// The fetcher
Future<String> fetchUser() async {
    final response = await http.get(
      Uri.parse('https://swapi.dev/api/people/${userId.value}/'),
    );
    return response.body;
}

// The resource
final user = Resource(fetcher: fetchUser, source: userId);
```

A Resource can also be driven from a [stream] instead of a Future.
In this case you just need to pass the `stream` field to the `Resource` class.

If you're using `ResourceBuilder` you can react to the state of the resource:

```dart
ResourceBuilder(
  resource: user,
  builder: (_, userState) {
    return userState.on(
      ready: (data) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(data),
              subtitle:
                  Text('refreshing: ${userState.isRefreshing}'),
            ),
            userState.isRefreshing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: user.refresh,
                    child: const Text('Refresh'),
                  ),
          ],
        );
      },
      error: (e, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString()),
            userState.isRefreshing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: user.refresh,
                    child: const Text('Refresh'),
                  ),
          ],
        );
      },
      loading: () {
        return const RepaintBoundary(
          child: CircularProgressIndicator(),
        );
      },
    );
  },
)
```

The `on` method forces you to handle all the states of a Resource (_ready_, _error_ and _loading_).
The are also other convenience methods to handle only specific states.
