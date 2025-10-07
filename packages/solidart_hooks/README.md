# solidart_hooks

For a comprehensive and updated documentation go to [The Official Documentation](https://solidart.mariuti.com)

---

Helper library to make working with [solidart](https://pub.dev/packages/solidart) in [flutter_hooks](https://pub.dev/packages/flutter_hooks) easier.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class Example extends HookWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);
    useSolidartEffect(() {
      debugPrint('Effect count: ${count.value}, doubleCount: ${doubleCount.value}');
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: ${count.value}'),
            Text('Double: ${doubleCount.value}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## useSignal

How to create a new signal inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    return Scaffold(
      body: Center(child: Text('Count: ${count.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

The widget will automatically rebuild when the value changes.
The signal will get disposed when the widget gets unmounted.

## useComputed

How to create a new computed signal inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(5);
    final doubled = useComputed(() => count.value * 2);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: ${count.value}'),
            Text('Doubled: ${doubled.value}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

The widget will automatically rebuild when the value changes.
The computed will get disposed when the widget gets unmounted.

## useSolidartEffect

How to create a new effect inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    useSolidartEffect(() {
      debugPrint('Effect triggered! Count: ${count.value}');
    });
    return Scaffold(
      body: Center(child: Text('Count: ${count.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## useListSignal

How to create a new list signal inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final items = useListSignal<String>(['Item1', 'Item2']);
    return Scaffold(
      body: Center(child: Text('Items: ${items.value.join(', ')}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => items.add('Item${items.value.length + 1}'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

The widget will automatically rebuild when the list changes.
The signal will get disposed when the widget gets unmounted.

## useSetSignal

How to create a new set signal inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final uniqueItems = useSetSignal<String>({'Item1', 'Item2'});
    return Scaffold(
      body: Center(child: Text('Items: ${uniqueItems.value.join(', ')}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => uniqueItems.add('Item${uniqueItems.value.length + 1}'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

The widget will automatically rebuild when the set changes.
The signal will get disposed when the widget gets unmounted.

## useMapSignal

How to create a new map signal inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final userRoles = useMapSignal<String, String>({'admin': 'John'});
    return Scaffold(
      body: Center(
        child: Text('Roles: ${userRoles.value.entries.map((e) => '${e.key}:${e.value}').join(', ')}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => userRoles['user${userRoles.value.length}'] = 'User${userRoles.value.length}',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

The widget will automatically rebuild when the map changes.
The signal will get disposed when the widget gets unmounted.

## useResource

How to create a new resource inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final userResource = useResource(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 'Data loaded';
    });

    return Scaffold(
      body: Center(
        child: userResource.state.on(
          ready: (data) => Text('Result: $data'),
          error: (error, stackTrace) => Text('Error: $error'),
          loading: () => const CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => userResource.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

The widget will automatically rebuild when the resource state changes.
The resource will get disposed when the widget gets unmounted.

## useResourceStream

How to create a new resource from a stream inside of a hook widget:

```dart
class Example extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final streamResource = useResourceStream<int>(() {
      return Stream.periodic(const Duration(seconds: 1), (count) => count);
    });

    return Scaffold(
      body: Center(
        child: streamResource.state.on(
          ready: (data) => Text('Stream value: $data'),
          error: (error, stackTrace) => Text('Error: $error'),
          loading: () => const CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => streamResource.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

The widget will automatically rebuild when the resource state changes.
The resource will get disposed when the widget gets unmounted.

## useExistingSignal

How to bind an existing signal inside of a hook widget:

```dart
class UseExistingSignalExample extends StatefulHookWidget {
  const UseExistingSignalExample({super.key});

  @override
  State<UseExistingSignalExample> createState() =>
      _UseExistingSignalExampleState();
}

class _UseExistingSignalExampleState extends State<UseExistingSignalExample> {
  final existingSignal = Signal(42);

  @override
  Widget build(BuildContext context) {
    final boundSignal = useExistingSignal(existingSignal);

    return Scaffold(
      body: Center(child: Text('Value: ${boundSignal.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => existingSignal.value++,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    existingSignal.dispose();
    super.dispose();
  }
}
```

The widget will automatically rebuild when the value changes.
The signal will NOT get disposed when the widget gets unmounted (unless autoDispose is true).
