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
