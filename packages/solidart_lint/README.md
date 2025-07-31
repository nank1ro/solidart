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

### Wrap with Solid (Renamed into ``rap with ProviderScope`)

![Wrap with Solid sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_solid.gif)

### Wrap with SignalBuilder

![Wrap with SignalBuilder sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_signal_builder.gif)

### Wrap with Show

![Wrap with Show sample](https://raw.githubusercontent.com/nank1ro/solidart/main/packages/solidart_lint/assets/wrap_with_show.gif)
