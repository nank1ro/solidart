[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nank1ro/solidart)](https://gitHub.com/nank1ro/solidart/stargazers/)
[![Coverage](https://codecov.io/gh/nank1ro/solidart/branch/main/graph/badge.svg?token=HvJYtaixiW)](https://codecov.io/gh/nank1ro/solidart)
[![GitHub issues](https://img.shields.io/github/issues/nank1ro/solidart)](https://github.com/nank1ro/solidart/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/nank1ro/solidart.svg)](https://gitHub.com/nank1ro/solidart/pull/)
[![solidart Pub Version (including pre-releases)](https://img.shields.io/pub/v/solidart?include_prereleases)](https://pub.dev/packages/solidart)
[![flutter_solidart Pub Version (including pre-releases)](https://img.shields.io/pub/v/flutter_solidart?include_prereleases)](https://pub.dev/packages/flutter_solidart)
[![All Contributors](https://img.shields.io/github/all-contributors/nank1ro/solidart?color=ee8449&style=flat-square)](#contributors)
[![](https://dcbadge.vercel.app/api/server/PvaDkncs)](https://discord.gg/2JBzeeQShh)

# A simple state-management library inspired by SolidJS.

The objectives of this project are:

1. Being simple and easy to learn
2. Fits well with the framework's good practices
3. Do not have a single global state, but multiple states only in the most appropriate places
4. No code generation

## Learning

For a comprehensive and updated documentation go to [The Official Documentation](https://docs.page/nank1ro/solidart)

There are 5 main concepts you should be aware:

1. [Signals](#signals)
2. [Effects](#effects)
3. [Computed](#computed)
4. [Resources](#resources)
5. [Solid (only flutter_solidart)](#solid)

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

### Solid

The Flutter framework works like a Tree. There are ancestors and there are descendants.

You may incur the need to pass a Signal deep into the tree, this is discouraged.
You should never pass a signal as a parameter.

To avoid this there's the _Solid_ widget.

With this widget you can pass a signal down the tree to anyone who needs it.

You will have already seen `Theme.of(context)` or `MediaQuery.of(context)`, the procedure is practically the same.

Let's see an example to grasp the concept.

You're going to see how to build a toggle theme feature using `Solid`, this example is present also here https://github.com/nank1ro/solidart/tree/main/examples/toggle_theme

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the theme mode signal to descendats
    return Solid( // [1]
      providers: [
        Provider<Signal<ThemeMode>>(
          create: () => Signal(ThemeMode.light),
        ),
      ],
      // using the builder method to immediately access the signal
      builder: (context) {
        // observe the theme mode value this will rebuild every time the themeMode signal changes.
        final themeMode = context.observe<ThemeMode>(); // [2]
        return MaterialApp(
          title: 'Toggle theme',
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // retrieve the theme mode signal
    final themeMode = context.get<Signal<ThemeMode>>(); // [3]
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toggle theme'),
      ),
      body: Center(
        child:
            // Listen to the theme mode signal rebuilding only the IconButton
            SignalBuilder( // [4]
          signal: themeMode,
          builder: (_, mode, __) {
            return IconButton(
              onPressed: () { // [5]
                // toggle the theme mode
                if (themeMode.value == ThemeMode.light) {
                  themeMode.value = ThemeMode.dark;
                } else {
                  themeMode.value = ThemeMode.light;
                }
              },
              icon: Icon(
                mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
              ),
            );
          },
        ),
      ),
    );
  }
}
```

First at `[1]` we've used the `Solid` widget to provide the `themeMode` signal to descendants.

The `Solid` widgets takes a list of providers:
 The `Provider` has a `create` function that returns the signal.
You may create a signal or a derived signal. The value is a Function
because the signal is created lazily only when used for the first time, if
you never access the signal it never gets created.
In the `Provider` you can also specify an `id`entifier for having multiple
signals of the same type.

At `[2]` we `observe` the value of a signal. The `observe` method listen to the signal value and rebuilds the widget when the value changes. It takes an optional `id` that is the signal identifier that you want to use. This method must be called only inside the `build` method.

At `[3]` we `get` the signal with the given signal type. This doesn't listen to signal value. You may use this method inside the `initState` and `build` methods.

At `[4]` using the `SignalBuilder` widget we rebuild the `IconButton` every time the signal value changes.

And finally at `[5]` we update the signal value.

> It is mandatory to pass the type of signal value otherwise you're going to encounter an error, for example:

```dart
Provider<Signal<ThemeMode>>(create: () => Signal(ThemeMode.light))
```
and `context.observe<ThemeMode>` where ThemeMode is the type of the signal
value.
`context.get<Signal<ThemeMode>>` where `Signal<ThemeMode>` is the type
of signal with its type value.

## Examples

### Sample features using flutter_solidart:

- [Counter](https://zapp.run/github/nank1ro/solidart/tree/main/examples/counter)
- [Toggle theme (dark/light mode)](https://zapp.run/github/nank1ro/solidart/tree/main/examples/toggle_theme)
- [Todos](https://zapp.run/github/nank1ro/solidart/tree/main/examples/todos)
- [Github Search](https://zapp.run/github/nank1ro/solidart/tree/main/examples/github_search)

### Showcase of all flutter_solidart features

- [Showcase of all features](https://zapp.run/github/nank1ro/solidart/tree/main/packages/flutter_solidart/example)

Learn every feature of `flutter_solidart` including:

1. `Signal`
2. `Show` widget
3. `Computed`
4. `Effect`s
5. `SignalBuilder`, `DualSignalBuilder` and `TripleSignalBuilder`
6. `Resource` and `ResourceBuilder`
7. `Solid` and its fine-grained reactivity

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://www.bestofcode.dev"><img src="https://avatars.githubusercontent.com/u/60045235?v=4?s=100" width="100px;" alt="Alexandru Mariuti"/><br /><sub><b>Alexandru Mariuti</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Code">💻</a> <a href="https://github.com/nank1ro/solidart/issues?q=author%3Anank1ro" title="Bug reports">🐛</a> <a href="#maintenance-nank1ro" title="Maintenance">🚧</a> <a href="#question-nank1ro" title="Answering Questions">💬</a> <a href="https://github.com/nank1ro/solidart/pulls?q=is%3Apr+reviewed-by%3Anank1ro" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Documentation">📖</a> <a href="https://github.com/nank1ro/solidart/commits?author=nank1ro" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/manuel-plavsic"><img src="https://avatars.githubusercontent.com/u/55398763?v=4?s=100" width="100px;" alt="manuel-plavsic"/><br /><sub><b>manuel-plavsic</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=manuel-plavsic" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/luketg8"><img src="https://avatars.githubusercontent.com/u/10770936?v=4?s=100" width="100px;" alt="Luke Greenwood"/><br /><sub><b>Luke Greenwood</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=luketg8" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/9dan"><img src="https://avatars.githubusercontent.com/u/32853831?v=4?s=100" width="100px;" alt="9dan"/><br /><sub><b>9dan</b></sub></a><br /><a href="https://github.com/nank1ro/solidart/commits?author=9dan" title="Code">💻</a> <a href="https://github.com/nank1ro/solidart/issues?q=author%3A9dan" title="Bug reports">🐛</a> <a href="https://github.com/nank1ro/solidart/commits?author=9dan" title="Documentation">📖</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
