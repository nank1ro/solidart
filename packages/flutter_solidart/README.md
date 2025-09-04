[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nank1ro/solidart)](https://gitHub.com/nank1ro/solidart/stargazers/)
[![Coverage](https://codecov.io/gh/nank1ro/solidart/branch/main/graph/badge.svg?token=HvJYtaixiW)](https://codecov.io/gh/nank1ro/solidart)
[![GitHub issues](https://img.shields.io/github/issues/nank1ro/solidart)](https://github.com/nank1ro/solidart/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/nank1ro/solidart.svg)](https://gitHub.com/nank1ro/solidart/pull/)
[![solidart Pub Version](https://img.shields.io/pub/v/solidart?label=solidart)](https://pub.dev/packages/solidart)
[![flutter_solidart Pub Version](https://img.shields.io/pub/v/flutter_solidart?label=flutter_solidart)](https://pub.dev/packages/flutter_solidart)
[![All Contributors](https://img.shields.io/github/all-contributors/nank1ro/solidart?color=ee8449&style=flat-square)](#contributors)
[![](https://dcbadge.vercel.app/api/server/2JBzeeQShh)](https://discord.gg/2JBzeeQShh)

# A simple state-management library inspired by SolidJS.

The objectives of this project are:

1. Being simple and easy to learn
2. Fits well with the framework's good practices
3. Do not have a single global state, but multiple states only in the most appropriate places
4. No code generation

## Learning

For a comprehensive and updated documentation go to [The Official Documentation](https://solidart.mariuti.com)

There are 5 main concepts you should be aware:

1. [Signal](#signal)
2. [Effect](#effect)
3. [Computed](#computed)
4. [Resource](#resource)
5. [Dependency Injection](#dependency-injection)

### Signal

Signals are the cornerstone of reactivity in _solidart_. They contain values that change over time; when you change a signal's value, it automatically updates anything that uses it.

To create a signal, you have to use the `Signal` class:

```dart
final counter = Signal(0);
```

The argument passed to the class is the initial value, and the return value is the signal.

To retrieve the current value, you can use:

```dart
print(counter.value); // prints 0
```

To change the value, you can use:

```dart
// Set the value to 2
counter.value = 2;
// Update the value based on the current value
counter.updateValue((value) => value * 2);
```

### Effect

Signals are trackable values, but they are only one half of the equation. To complement those are observers that can be updated by those trackable values. An effect is one such observer; it runs a side effect that depends on signals.

An effect can be created by using the `Effect` class.
The effect automatically subscribes to any signal and reruns when any of them change.
So let's create an Effect that reruns whenever `counter` changes:

```dart
final disposeFn = Effect(() {
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

### Resource

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
      Uri.parse('https://jsonplaceholder.typicode.com/users/${userId.value}/'),
      headers: {'Accept': 'application/json'},      
    );
    return response.body;
}

// The resource
final user = Resource(fetchUser, source: userId);
```

A Resource can also be driven from a [stream] instead of a Future.
In this case you just need to pass the `stream` field to the `Resource` class.

If you're using `SignalBuilder` you can react to the state of the resource:

```dart
SignalBuilder(
  builder: (_, __) {
    return user.state.on(
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

### Dependency Injection

The dependency injection in `flutter_solidart` is done using the [disco](https://disco.mariuti.com) package.

This replaced the `Solid` widget which was used in the previous versions of `flutter_solidart`.

[disco](https://disco.mariuti.com) has been built on top of `Solid` to provide a more powerful and flexible way to handle dependency injection.

[Refer to the official disco documentation](https://disco.mariuti.com) which contains also examples written with `flutter_solidart`

## DevTools

<img src="https://raw.githubusercontent.com/nank1ro/solidart/main/assets/devtools.png" width="100%">

You can debug your application using the Solidart DevTools extension and filter your signals.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://mariuti.com"><img src="https://avatars.githubusercontent.com/u/60045235?v=4?s=100" width="100px;" alt="Alexandru Mariuti"/><br /><sub><b>Alexandru Mariuti</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Code">💻</a> <a href="https://github.com/nank1ro/solidart/issues?q=author%3Anank1ro" title="Bug reports">🐛</a> <a href="#maintenance-nank1ro" title="Maintenance">🚧</a> <a href="#question-nank1ro" title="Answering Questions">💬</a> <a href="https://github.com/nank1ro/solidart/pulls?q=is%3Apr+reviewed-by%3Anank1ro" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Documentation">📖</a> <a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/manuel-plavsic"><img src="https://avatars.githubusercontent.com/u/55398763?v=4?s=100" width="100px;" alt="manuel-plavsic"/><br /><sub><b>manuel-plavsic</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=manuel-plavsic" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/luketg8"><img src="https://avatars.githubusercontent.com/u/10770936?v=4?s=100" width="100px;" alt="Luke Greenwood"/><br /><sub><b>Luke Greenwood</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=luketg8" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/9dan"><img src="https://avatars.githubusercontent.com/u/32853831?v=4?s=100" width="100px;" alt="9dan"/><br /><sub><b>9dan</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=9dan" title="Code">💻</a> <a href="https://github.com/nank1ro/solidart/issues?q=author%3A9dan" title="Bug reports">🐛</a> <a href="https://github.com/nank1ro/solidart/commits?author=9dan" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://medz.dev"><img src="https://avatars.githubusercontent.com/u/5564821?v=4?s=100" width="100px;" alt="Seven Du"/><br /><sub><b>Seven Du</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=medz" title="Code">💻</a> <a href="https://github.com/nank1ro/solidart/issues?q=author%3Amedz" title="Bug reports">🐛</a> <a href="https://github.com/nank1ro/solidart/commits?author=medz" title="Documentation">📖</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
