[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nank1ro/solidart)](https://gitHub.com/nank1ro/solidart/stargazers/)
[![Coverage](https://codecov.io/gh/nank1ro/solidart/branch/main/graph/badge.svg?token=HvJYtaixiW)](https://codecov.io/gh/nank1ro/solidart)
[![GitHub issues](https://img.shields.io/github/issues/nank1ro/solidart)](https://github.com/nank1ro/solidart/issues/)
[![GitHub pull-requests](https://img.shields.io/github/issues-pr/nank1ro/solidart.svg)](https://gitHub.com/nank1ro/solidart/pull/)
[![flutter_solidart Pub Version (including pre-releases)](https://img.shields.io/pub/v/flutter_solidart?include_prereleases)](https://pub.dev/packages/flutter_solidart)

# A simple state-management library inspired by SolidJS.

The objectives of this project are:

1. Being simple and easy to learn
2. Do not go against the framework (e.g. Flutter) with weird workarounds.
3. Do not have a single global state, but put multiple states only in the most appropriate places
4. No code generation

## Learning

For a comprehensive and updated documentation go to [The Official Documentation](https://docs.page/nank1ro/solidart)

There are 4 main concepts you should be aware:

1. [Signals](#signals)
2. [Effects](#effects)
3. [Resources](#resources)
4. [Solid](#solid)

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
// equal to
print(counter());

// Change the counter value
counter.value++; // Increments by 1
// or
counter.value = 2; // Sets the value to 2
// or
counter.set(3);
// or
counter.update((value) => value * 2); // Update the value based on the current value
```

If you're using `flutter_solidart` you can use the `SignalBuilder` widget to automatically react to the signal value, for example:

```dart
SignalBuilder(
  signal: counter,
  builder: (_, value, __) {
    return Text('$value');
  },
)
```

### Effects

Signals are trackable values, but they are only one half of the equation. To complement those are observers that can be updated by those trackable values. An effect is one such observer; it runs a side effect that depends on signals.

An effect can be created by using `createEffect`.
The effect automatically subscribes to any signal and reruns when any of them change.
So let's create an Effect that reruns whenever `counter` changes:

```dart
final disposeFn = createEffect((_) {
    print("The count is now ${counter.value}");
});
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

A Resource can also be driven from a [stream] instead of a Future.
In this case you just need to pass the `stream` field to the `createResource` method.

Using `ResourceBuilder` you can react to the state of the resource:

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
        SolidSignal<Signal<ThemeMode>>(
          create: () => createSignal(ThemeMode.light),
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
 The `SolidSignal` has a `create` function that returns a `SignalBase`.
You may create a signal or a derived signal. The value is a Function
because the signal is created lazily only when used for the first time, if
you never access the signal it never gets created.
In the `SolidSignal` you can also specify an `id`entifier for having multiple
signals of the same type.

At `[2]` we `observe` the value of a signal. The `observe` method listen to the signal value and rebuilds the widget when the value changes. It takes an optional `id` that is the signal identifier that you want to use. This method must be called only inside the `build` method.

At `[3]` we `get` the signal with the given signal type. This doesn't listen to signal value. You may use this method inside the `initState` and `build` methods.

At `[4]` using the `SignalBuilder` widget we rebuild the `IconButton` every time the signal value changes.

And finally at `[5]` we update the signal value.

> It is mandatory to pass the type of signal value otherwise you're going to encounter an error, for example:

```dart
SolidSignal<Signal<ThemeMode>>(create: () => createSignal(ThemeMode.light))
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
- [Github Search](https://zapp.run/github/nank1ro/solidart/tree/dev/examples/github_search)

### Showcase of all flutter_solidart features

- [Showcase of all features](https://zapp.run/github/nank1ro/solidart/tree/main/packages/flutter_solidart/example)

Learn every feature of `flutter_solidart` including:

1. `createSignal`
2. `Show` widget
3. Derived signals with `createComputed`
4. `Effect`s with basic and advanced usages
5. `SignalBuilder`, `DualSignalBuilder` and `TripleSignalBuilder`
6. `createResource` and `ResourceBuilder`
7. `Solid` and its fine-grained reactivity
