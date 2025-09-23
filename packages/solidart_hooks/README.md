# solidart_hooks

For a comprehensive and updated documentation go to [The Official Documentation](https://solidart.mariuti.com)

[![solidart_hooks Pub Version](https://img.shields.io/pub/v/solidart_hooks)](https://pub.dev/packages/solidart_hooks)

---

Helper library to make working with [Solidart](https://pub.dev/packages/solidart) in Flutter easier.

```dart
import 'package:flutter/material.dart';
import 'package:solidart_hooks/solidart_hooks.dart';

class Counter extends SolidartWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);

    return Scaffold(
      body: Center(child: Text("Count: ${count.value}")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: const Icon(Icons.plus_one),
      ),
    );
  }
}
```

## useSignal

How to create a new signal inside of a hook widget:

```dart
class Example extends SolidartWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    return Text('Count: ${count.value}');
  }
}
```

The widget will automatically rebuild when the value changes.
The signal will get disposed when the widget gets unmounted.

## useComputed

How to create a new computed signal inside of a hook widget:

```dart
class Example extends SolidartWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final doubleCount = useComputed(() => count.value * 2);
    return Text('Count: ${count.value}, Double: ${doubleCount.value}');
  }
}
```

The widget will automatically rebuild when the value changes.
The computed will get disposed when the widget gets unmounted.

## useEffect

How to create a new effect inside of a hook widget:

```dart
class Example extends SolidartWidget {
  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    useEffect(() {
        print('count: ${count.value}');
    });
    return Text('Count: ${count.value}');
  }
}
```

## Use existing signals

How to bind an existing signal inside of a hook widget:

```dart
class Example extends SolidartWidget {
  Example(this.count);

  final Signal<int> count;

  @override
  Widget build(BuildContext context) {
    return Text('Count: ${count.value}');
  }
}
```

The widget will automatically rebuild when the value changes.
The signal will NOT get disposed when the widget gets unmounted (unless autoDispose is true).
