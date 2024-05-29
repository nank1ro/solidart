This package is a developer tool for users of flutter_solidart, designed to help stop common issues and simplify repetitive tasks.

> I highly recommend using this package to avoid errors and understand how to properly use flutter_solidart

## Getting started

Run this command in the root of your Flutter project:

```sh
flutter pub add -d solidart_lint custom_lint
```

Then edit your `analysis_options.yaml` file and add these lines of code:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Then run:

```sh
flutter clean
flutter pub get
dart run custom_lint
```

## ASSISTS

### Wrap with Solid

![Wrap with Solid sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_solid.gif)

### Wrap with SignalBuilder

![Wrap with SignalBuilder sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_signal_builder.gif)

### Wrap with Show

![Wrap with Show sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_show.gif)

## LINTS

### avoid_dynamic_solid_provider

`Provider` cannot be dynamic

**Bad**:

```dart
Solid(
  providers: [
    Provider(create: () => MyClass()),
  ],
),
```

**Good**:

```dart
Solid(
  providers: [
    Provider<MyClass>(create: () => MyClass()),
  ],
),
```

---

### avoid_dynamic_solid_signal

Solid `signals` cannot be dynamic

**Bad**:

```dart
Solid(
  signals: {
    'id': () => Signal(0),
  },
),
```

**Good**:

```dart
Solid(
  signals: {
    'id': () => Signal<int>(0),
  },
),
```

---

### invalid_provider_type

The provider type you want to retrieve is invalid, must not implement `SignalBase`.
You cannot retrieve a provider that implements `SignalBase`, like `Signal`, `ReadSignal` and `Resource`.

**Bad**:

```dart
final provider = context.get<Signal<MyClass>>();
```

**Good**:

```dart
final provider = context.get<MyClass>();
```

---

### invalid_signal_type

The signal type you want to retrieve is invalid, must implement `SignalBase`.
You can retrieve signals that implement `SignalBase`, like `Signal`, `ReadSignal` and `Resource`.

**Bad**:

```dart
final signal = context.get<MyClass>('signal-id');
```

**Good**:

```dart
final signal = context.get<Signal<int>>('signal-id');
```

---

### invalid_solid_get_type

Specify the provider or signal type you want to get.

**Bad**:

```dart
final provider = context.get();
```

**Good**:

```dart
final provider = context.get<MyClass>();
```

---

### invalid_update_type

The update type is invalid, must not implement `SignalBase`.
You cannot update a signal that implements `SignalBase`, like `Signal`, `ReadSignal` and `Resource`.

**Bad**:

```dart
context.update<Signal<int>>('counter', (value) => value * 2);
```

**Good**:

```dart
context.update<int>('counter', (value) => value * 2);
```
