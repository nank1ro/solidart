# Solidart - State Management Library
Solidart is a Dart/Flutter state management library inspired by SolidJS. It provides Signal-based reactive programming with comprehensive Flutter integration, linting tools, and DevTools support.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Environment Setup
Install Flutter and Dart SDK (required for all development):
- **CRITICAL**: Download Flutter stable channel from https://flutter.dev/docs/get-started/install
- Add Flutter to PATH: `export PATH="/path/to/flutter/bin:$PATH"`  
- Verify installation: `flutter --version && dart --version`
- **NEVER CANCEL**: Initial Flutter setup and first `flutter doctor` can take 5-10 minutes

### Bootstrap, Build, and Test the Repository
Run these commands in order from the repository root:

1. **Install Dependencies** (2-3 minutes):
   ```bash
   flutter pub get
   ```
   - NEVER CANCEL: This resolves all workspace packages and can take 2-3 minutes
   - Downloads dependencies for all packages in the workspace

2. **Analyze Code** (1-2 minutes):
   ```bash
   flutter analyze packages  
   ```
   - Runs static analysis on all packages
   - Expected: 4 linting issues in solidart package (avoid_renaming_method_parameters, cascade_invocations)
   - These are existing known issues, not errors

3. **Run Tests with Coverage** (8-12 minutes):
   ```bash
   flutter test packages --coverage
   ```
   - **NEVER CANCEL**: Full test suite takes 8-12 minutes. Set timeout to 20+ minutes.
   - Runs 143+ tests across all packages  
   - Generates coverage reports in coverage/lcov.info
   - Individual package tests typically complete in under 10 seconds each

### Documentation
Build and serve documentation (Astro/Starlight framework):
- **Install Dependencies** (15-25 seconds):
  ```bash
  cd docs-v2 && npm install
  ```
- **Build Documentation** (3-6 seconds):
  ```bash
  npm run build
  ```
- **Serve Locally** (starts in 1-2 seconds):
  ```bash
  npm run dev
  ```
  - Serves at `http://localhost:4321`
  - Hot reload enabled for development

### Performance Benchmarking
Run performance benchmarks against other reactive libraries:
```bash
flutter pub get  # Required for benchmark dependencies
dart benchmark.dart
```
- Compares Solidart performance with other reactive frameworks
- Requires full workspace dependencies to be installed
When working on specific packages, you can work faster by targeting individual packages:

**Solidart Core Package** (packages/solidart):
- Dart-only package, no Flutter dependencies
- `cd packages/solidart && dart pub get` (6-8 seconds)
- `dart analyze .` (2-3 seconds) 
- `dart test --coverage=coverage` (8-10 seconds, 143 tests)

**Flutter Solidart Package** (packages/flutter_solidart):
- Requires Flutter SDK and dependencies
- `cd packages/flutter_solidart && flutter pub get`
- `flutter test` for widget tests

**Example Applications**:
- Counter: `examples/counter/` - Basic state management demo
- Todos: `examples/todos/` - Complex state with lists  
- GitHub Search: `examples/github_search/` - Network requests with Resources
- Toggle Theme: `examples/toggle_theme/` - Theme switching demo

**Running Example Applications**:
```bash
cd examples/counter
flutter pub get  # Install dependencies (30-60 seconds)
flutter run -d web-server --web-port=8080  # Run on web (2-3 minutes first build)
```
- **NEVER CANCEL**: First Flutter build takes 2-5 minutes
- Subsequent builds are much faster (10-30 seconds)
- Examples demonstrate real user scenarios for testing changes

## Validation and Quality Assurance

### Pre-commit Validation
ALWAYS run these commands before committing changes:
1. `flutter analyze packages` - Must pass with no new warnings
2. `flutter test packages --coverage` - All tests must pass  
3. For documentation changes: `cd docs-v2 && npm run build`

### Manual Testing Scenarios
After making changes to core functionality, ALWAYS test these scenarios:

**Basic Signal Operations**:
- Create a signal: `final counter = Signal(0);`
- Update value: `counter.value = 1;`  
- Access value: `print(counter.value);`

**Effect System**:
- Create reactive effect: `Effect(() => print(counter.value));`
- Verify effect runs when signal changes

**Computed Signals**:
- Create derived signal: `final doubled = Computed(() => counter.value * 2);`
- Verify computed updates when source changes

**Resource Loading**:
- Create async resource: `final resource = Resource(() => Future.value(data));`
- Test loading, ready, and error states

### Flutter Widget Testing (if modifying flutter_solidart)
- Test `SignalBuilder` rebuilds on signal changes
- Test `Provider` dependency injection
- Test `Show` conditional rendering widget

## Common Tasks and Repository Structure

### Package Organization
```
packages/
├── solidart/                 # Core reactive system (Dart only)
├── flutter_solidart/         # Flutter widgets and integration  
├── solidart_lint/           # Custom linting rules
└── solidart_devtools_extension/  # DevTools integration

examples/
├── counter/                 # Basic counter demo
├── todos/                   # Todo list application
├── github_search/           # API integration example  
└── toggle_theme/            # Theme switching example

docs-v2/                     # Documentation (Astro/Starlight)
```

### Key Files to Check After Changes
- **Signal changes**: Always test `packages/solidart/test/solidart_test.dart`
- **Flutter integration**: Always test `packages/flutter_solidart/test/flutter_solidart_test.dart`  
- **API changes**: Update documentation in `docs-v2/src/content/docs/`
- **Linting changes**: Test `packages/solidart_lint/` examples

### Build Timing Expectations
Based on validation runs:
- `flutter pub get`: 2-3 minutes (workspace with all packages)
- `flutter analyze packages`: 1-2 minutes  
- `flutter test packages --coverage`: 8-12 minutes (143+ tests)
- `dart pub get` (single package): 6-8 seconds
- `dart test` (single package): 8-10 seconds
- `npm install` (docs): 15-25 seconds
- `npm run build` (docs): 3-6 seconds

### Known Issues and Workarounds
- **Network restrictions**: If Flutter downloads fail, follow official Flutter installation guide
- **Workspace resolution errors**: Some commands require running in individual package directories
- **Coverage files**: Generated in `coverage/lcov.info` - include in CI reports
- **Benchmark script**: `benchmark.dart` requires full workspace setup with `flutter pub get` to access benchmark dependencies

### CI Build Process
The GitHub Actions workflow (`.github/workflows/build.yml`) runs:
1. Install Flutter stable channel
2. `flutter pub get` (all packages)
3. `flutter analyze packages` (static analysis)  
4. `flutter test packages --coverage` (run all tests)
5. Upload coverage to Codecov

Match this process exactly for local validation.

## Development Best Practices
- **Reactive patterns**: Use Signals for state, Effects for side effects, Computed for derived values
- **Testing**: Write unit tests for all Signal operations and state transitions
- **Performance**: Use `untracked()` for reads that shouldn't trigger reactivity
- **Memory management**: Signals auto-dispose in Flutter contexts, manually dispose in pure Dart
- **Documentation**: Update docs-v2 for any API changes or new features

Always build and exercise your changes with the provided examples and test scenarios to ensure compatibility across the entire library ecosystem.