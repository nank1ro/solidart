## 3.0.0-dev.3

- **FEAT**: `Signal`, `ReadableSignal`, `Computed`, `Resource`, and the collection signals now implement `package:listen`'s `ValueListenable`/`ValueNotifier` natively in pure Dart, exposing `addListener`/`removeListener` (plus `hasListeners`/`notifyListeners` on the mutable signals). Listeners participate in auto-disposal: adding one keeps the signal alive, and removing the last one lets an `autoDispose` signal dispose itself. Listeners follow `ChangeNotifier` registration and error semantics: each `addListener` call is a separate registration, and listener errors go to `Listenable.onError`. A `Computed` selector error is not a listener error: it is thrown to the code that triggers the computation, including `addListener()`. Listeners differ from `ChangeNotifier` in some ways, including: a listener is not notified of its own write; writes inside `batch()` notify at most once, at the end of the batch; `addListener()` on a disposed signal is a no-op (`ChangeNotifier` throws in debug mode); and a `notifyListeners()` call made from inside a listener does not call that listener again. In that case, listeners that have not run yet in the current notification run once, and other listeners that already ran are called again. `notifyListeners()` reaches every dependent of the signal: effects and listeners rerun. A computed that a listener or effect depends on recomputes when notifications run (at the end of the batch, if one is active), and notifies them only if its value changed. Any other computed recomputes on its next read. The `ReadSignal` type is also a `ValueListenable`.
- **FIX**: A `Computed` whose selector throws now recovers when one of its dependencies changes, also when its first evaluation throws ([#183](https://github.com/nank1ro/solidart/issues/183)). An effect that reads a `Computed` keeps running after the `Computed` throws and recovers ([#192](https://github.com/nank1ro/solidart/issues/192)). The error is thrown where the effect reads the `Computed`, so the effect's `onError` can handle it. A comparator that throws no longer breaks the `Computed`: the new value is kept, subscribers are notified, and the error is reported to the current `Zone` instead of being thrown to the code that triggered the update.
- **BREAKING**: `solidart` requires Dart 3.13 or later and `alien_signals` 2.4.0 or later. `Computed` now uses the error caching of `alien_signals`.
- **FIX**: An `autoDispose` `Computed` whose evaluation throws now disposes its `autoDispose` dependencies when it is disposed ([#200](https://github.com/nank1ro/solidart/issues/200)). A nullable `Computed` no longer reports a previous value after its first evaluation returns `null` ([#201](https://github.com/nank1ro/solidart/issues/201)).
- **FIX**: Assigning a new collection to `ListSignal.value`, `MapSignal.value` or `SetSignal.value` notifies observers and effects once instead of twice, like `Signal`. A listener that assigns the collection again during that notification no longer leaves `value` and `untrackedValue` out of sync. Assigning a `MapSignal` or `SetSignal` inside an effect no longer makes the effect depend on it.
- **FIX**: `observe()` and `addListener()` on a lazy signal that has no value yet no longer throw a `StateError`. The listener is called on the first assignment. The first assignment of a lazy signal no longer reports the new value as the previous value. Disposing a lazy signal that has no value no longer throws when DevTools are enabled. Reading a lazy `Resource` after it is disposed no longer starts its fetcher or stream.
- **FIX**: Reading a `Resource` for the first time inside an effect (`Effect`, `observe()`, `SignalBuilder`) no longer makes that effect depend on the signals the fetcher reads. A stream `Resource` with a `source` keeps following the source after its first event when it is first read inside an effect.
- **FIX**: When the first run of an `Effect` throws and there is no `onError`, the effect is now disposed before the error is rethrown. This is the first run that happens when the effect is created (the default `autorun`). It does not apply to an effect created with `autorun: false` that you run later by hand. Before, the effect stayed subscribed to the signals it read, but the caller never got the handle to dispose it. So a failed `observe()` or `addListener()` no longer leaves a subscriber that cannot be removed ([#183](https://github.com/nank1ro/solidart/issues/183)). If disposal itself throws, the caller still gets the original error, and the disposal error goes to the current `Zone`. This also applies inside a `batch()`. An `Effect` with `onError` is unchanged when `onError` returns normally. If `onError` throws during that first run, the effect is now also disposed and the error from `onError` is rethrown.
- **FIX**: An `Effect` whose first run throws is now disposed before the effects queued by that run, so it cannot run again. An error from a queued effect no longer replaces the error of that run ([#197](https://github.com/nank1ro/solidart/issues/197)). An effect created with `autorun: false` or with `delay` stays alive after a failed run, because you already have it and can dispose it. Disposing an effect now also disposes the effects created inside it, and a disposed `delay` effect cancels its pending run ([#198](https://github.com/nank1ro/solidart/issues/198)). A `delay` effect with `autoDispose: true` now runs its first callback before it checks for auto-disposal ([#203](https://github.com/nank1ro/solidart/issues/203)). A `delay` effect now tracks the signals its callback reads and reruns after the delay when one of them changes. Changes made while a rerun is pending join that rerun ([#204](https://github.com/nank1ro/solidart/issues/204)). Known limitation ([#209](https://github.com/nank1ro/solidart/issues/209)): the rerun that starts the timer disposes the effects created by the callback, and an `autoDispose` signal that only they read, before the timer creates them again. A nested effect stopped by its parent now also offers auto-disposal to its dependencies ([#202](https://github.com/nank1ro/solidart/issues/202)). The offer waits until the work that stopped it has finished: the outermost batch, flush or `Computed` evaluation, or the top-level `dispose()`. So a parent effect or `Computed` that recreates a child reading the same `autoDispose` signal keeps that signal alive. A disposed `Computed` offers auto-disposal to its dependencies in the same way, also when its own `autoDispose` is false, after its `onDispose` callbacks, so they can subscribe to the dependencies of its child effects. The offer stops while effects queued by an `onDispose` callback run. A disposed effect no longer keeps references to the signals it read. A live effect no longer keeps a reference to a disposed signal, and a `Computed` no longer keeps references to the signals it stopped reading. When an `onDispose` callback or a `SolidartObserver.didDisposeSignal` throws, disposal now still visits every dependency, callback and observer, then rethrows the first error. Later errors go to the current `Zone` ([#199](https://github.com/nank1ro/solidart/issues/199)). `Resource.dispose()` also finishes and runs its `onDispose` callbacks when the disposal of its `source` throws. Disposing a `Computed` now notifies observers once. When the callback of `batch()` or a manual `Effect.run()` throws, the caller now gets that error. Errors from the effects and disposals at the end of the batch go to the current `Zone`. `Computed.run()` rethrows its selector error also when a cleanup at the end of the run evaluates the `Computed` again. Disposing an `Effect`, `Computed` or signal now runs outside dependency tracking, so an `onDispose` callback that reads a signal no longer subscribes the running effect. This includes the disposal of an effect whose first run fails inside another effect. A disposed `Resource` no longer subscribes to its `source` or stream, and no longer writes the result of a pending fetch or refetch. `refresh()` after disposal does nothing, and disposal cancels a pending debounced refresh. Two debounced resources on the same source now each refresh ([#205](https://github.com/nank1ro/solidart/issues/205), [#206](https://github.com/nank1ro/solidart/issues/206)). Disposing the last signal of an effect or `Computed` that a batch left pending no longer throws a null check error at the end of the batch. A failed `Computed` evaluation now records its inputs before the disposal drain at its end, and a `Computed.run()` does not notify again a change that a run in that drain already delivered. Also, a `Computed` left by its observers no longer keeps a reference to a disposed input ([#207](https://github.com/nank1ro/solidart/issues/207)).
- **BREAKING**: `SignalBase` has two new getters, `untrackedHasValue` and `untrackedHasPreviousValue`: the untracked versions of `hasValue` and `hasPreviousValue`. They never subscribe the running effect and never run a `Computed`'s selector (`Computed.untrackedHasValue` is always true). DevTools uses them. `Resource.hasValue` now resolves a lazy resource, like `state`, so `observe()` and `addListener()` read `hasValue` before `value` on every signal type. A class that implements `SignalBase` directly (for example a test double) must implement both. A subclass or test double that overrides `value` should also override `hasValue` and `untrackedHasValue`. One that overrides `previousValue` should also override `hasPreviousValue` and `untrackedHasPreviousValue`.
- **FIX**: Turning on DevTools no longer changes how signals behave: DevTools now reads values without tracking them, running a lazy selector or fetcher, or triggering auto-dispose. With DevTools on, a dependency-free `autoDispose` `Computed` is no longer disposed when it is created, a lazy `Computed` or `Resource` no longer computes or fetches when it is created, an `autoDispose` `Computed` is disposed when its last dependency is disposed, and an effect no longer depends on a signal it creates.
- **CHORE**: DevTools extension 0.3.0: it uses `shadcn_ui` 0.61 (built on `material_ui`) and follows the DevTools light or dark theme when it changes.
- **FIX**: When an effect throws while queued effects run (for example at the end of a `batch()`), the other queued effects still run, and the first error is rethrown after all of them. Before, the effects queued after the throwing one were skipped until their dependencies changed again. This also applies to an effect that reads a throwing `Computed` and to an `onError` handler that throws. An effect's `onError` now also handles errors from its reactive reruns, not only from its first run. An effect that writes a signal no longer runs other effects in the middle of its own run: the effects that the write triggers run after the writing effect ends. So an error from one of them can no longer stop the writing effect, or reach its `onError`.
- **FIX**: `untrackedPreviousValue` now returns the same value as `previousValue` (also on `Computed`), and `observe()` passes that value to its listener ([#190](https://github.com/nank1ro/solidart/issues/190)). Before, it ignored `trackPreviousValue: false`, and it was not updated by in-place changes to a `ListSignal`, `MapSignal` or `SetSignal` (`add`, `[]=`, `remove` and similar). A collection mutation that changes nothing no longer overwrites the previous value. Replacing a whole `MapSignal` or `SetSignal` keeps the old collection, with its equality, as the previous value. With `trackPreviousValue: false`, `Resource.untrackedPreviousState` and `Signal.toString()` now also report no previous value.
- **PERF**: Collection signals check only the affected slot for point writes and only the affected slots for list range writes. `MapSignal.update`, `putIfAbsent` and `addAll` check only the keys they touch. Mutations that only add or only remove elements or entries check the length and any nested signal writes. So do `replaceRange` with a `List` or `Set` of another length, and `MapSignal.addAll` into an empty map. A mutation with an empty `List` or `Set` (for example `addAll(const [])`), or `length =` with the current length, makes no copy. `updateAll`, `sort`, `shuffle`, `setAll` with an iterable that is not a `List`, and a non-empty `addEntries` still compare the whole collection, because their input can run code each time it is read. With `trackPreviousValue: false`, these checks avoid copying the full collection. With history on, the signal still makes one full copy for the previous value. With DevTools on, each change still serializes the whole collection. With history on, a `MapSignal` mutation copies the map before it changes it, so if a key's `hashCode` throws, the mutation throws and the map does not change.
- **FIX**: `ListSignal`, `MapSignal` and `SetSignal` mutations now follow one rule ([#196](https://github.com/nank1ro/solidart/issues/196)). A mutation that changes the collection notifies once, with the collection as it was before as the previous value. A mutation that changes nothing, or that throws before it changes anything, does not notify and keeps the previous value. A mutation that throws after a partial change (for example `addAll` from an iterable that throws) still notifies once. Mutations that only add or only remove elements or entries detect length changes and changes made through the signal inside a callback. With history on, a list mutation that can change the length (for example `add`, `insert`, `removeAt`, `remove`, `removeWhere`, `retainWhere`, `removeRange`, `replaceRange`, `addAll` or `insertAll`) and then throws also compares the elements, so elements moved before the error are found. A callback of a collection mutation that writes directly to the backing collection (for example `s.untrackedValue['b'] = 3` inside `update`) is seen only if it changes the length or a slot that the mutation checks. Writes through the signal are always seen. If a callback assigns a new collection during a mutation, the previous value is the collection as it was before the mutation started. If an effect or observer throws during that notification, the mutation's own error is still thrown, and the other error goes to the current `Zone`. Elements and values are compared with `identical`, so writing an equal but distinct object is a change. Each mutation runs on the underlying collection, so it returns and throws like the same call on a plain collection: for example, `sort` and `shuffle` change the list in place, and `remove` uses the set's own equality and returns `false` for an object of another type. `MapSignal.updateAll` behaves like the backing map's `updateAll`: if the callback throws partway, the entries already updated stay updated, and observers are notified once. `MapSignal.update`, `retainWhere` and `MapSignal.updateAll` now notify correctly, and a mutation inside an effect no longer makes the effect depend on the collection. For a `MapSignal` mutation, the previous value is a plain `Map`, without a custom key equality. Known limitation ([#208](https://github.com/nank1ro/solidart/issues/208)): collection signals detect changes by comparing elements with `identical`. So a typed SIMD list (for example `Float32x4List`, where each element read creates a new object) can report a change for a rejected or no-op mutation. A mutation of a `cast()` view that holds entries of the wrong type can throw a `TypeError`. `addAll({})` on a `cast()` map is a no-op.
- **CHORE**: Depend on `package:listen` for the `Listenable`/`ValueNotifier`/`ValueListenable` primitives. `solidart` stays pure Dart: it does not import Flutter. Since Flutter 3.50, `package:flutter/foundation.dart` re-exports these same `listen` types ([flutter/flutter#189111](https://github.com/flutter/flutter/pull/189111)), so in a Flutter app a signal is a Flutter `Listenable` and works directly with Flutter APIs. Flutter apps get `listen` from both `solidart` and the Flutter SDK, so the two constraints must agree (both use `^1.0.1`).

## 3.0.0-dev.2

- **FEAT**: `Resource` now exposes `previousReady` and `previousError` — the most recent ready / error state, retained across any number of intervening transitions (unlike `previousState`, which remembers only the single prior state). Handy to keep a UI populated across repeated refresh failures, e.g. `resource().asReady?.value ?? resource.previousReady?.value`. Gated by `trackPreviousValue`.

## 3.0.0-dev.1

- **BREAKING**: `SolidartConfig.autoDispose` now defaults to `false` — auto-dispose is opt-in from v3. Enable it globally (`SolidartConfig.autoDispose = true`) or per `Signal`/`Computed`/`Effect` via the `autoDispose` parameter.
- **FIX**: `Effect` now honours its per-instance `autoDispose` flag (defaulted from `SolidartConfig.autoDispose` at creation), consistent with `Signal` and `Computed`. Previously an effect only auto-disposed when the global `SolidartConfig.autoDispose` was enabled, ignoring a per-instance `autoDispose: true`.
- **CHORE**: Upgrade `alien_signals` to `^2.3.1` and adapt the internal reactive adapter to its preset/system APIs.
- **FIX**: A lazy nullable `Signal` (e.g. `Signal<int?>.lazy()`) now notifies when it is first set to `null`; previously the `None` → `Some(null)` transition was treated as "no change".
- **FIX**: Disposing a signal now fully unlinks its subscribers on both sides of each dependency link — and does so regardless of `SolidartConfig.autoDispose` (a disposed signal is destroyed, like `Effect`/`Computed` disposal) — so a later write to the disposed signal can no longer propagate into an already-detached computed.
- **FIX**: `Computed.listenerCount` now reports the number of subscribers instead of the number of dependencies. This also corrects `Resource`'s source cleanup, which uses `listenerCount` to decide whether to dispose a `Computed` passed as its `source`.
- **FIX**: Disposing a `Computed` now unlinks all of its subscribers instead of only the first (leaving no dangling links back to it) and offers each subscriber the chance to auto-dispose, matching signal disposal.
- **REFACTOR**: `ReactiveSystem`, `reactiveSystem`, and the `MayDisposeDependencies` extension are no longer exported from the public `solidart.dart` barrel — they expose internal `alien_signals` types and are implementation detail. Sibling packages consume them via `package:solidart/solidart_internal.dart`.

## 2.8.6

- **FIX**: Prevent effect re-entrancy when a signal is written during the effect's first run. The write no longer re-enters the running effect mid-execution, which could throw `LateInitializationError`.

## 2.8.5

- **FIX**: Return up-to-date value from `Computed.untrackedValue` after dependency changes.

## 2.8.4

- **FIX**: Prevent `LateInitializationError` when accessing `Computed.untrackedValue` before first `value` access. `hasValue` now triggers lazy computation, and `untrackedValue` asserts with a clear message if accessed before computation.

## 2.8.3

- **FIX**: Handle race conditions in Resource that caused multiple calls to `resolve`.

## 2.8.2

- **REFACTOR**: Improve the Solidart DevTools extension by giving any signal an id and omit overriding the same signal by name.

## 2.8.1

- **FIX**: Expose `until` method for `Computed`.

## 2.8.0

- **REFACTOR**: Deprecate `maybeOn` and `on` methods of `ResourceState`. Use `maybeWhen` and `when` instead.

## 2.7.1

- **REFACTOR**: Rename `update` to `shouldUpdate` in `ReadableSignal`.

## 2.7.0

- **FEAT**: Add `then` extension method to `FutureOr`. This allows you to use the `then` method on both `Future` and `FutureOr` values seamlessly. Mainly needed to simplify the usage of `ReadableSignal.until` and `Resource.untilReady` methods.
  ```dart
  final count = Signal(10);
  count.until((value) => value > 5).then((value) {
    print('The count is now greater than 5: $value');
  });
  ```

## 2.6.1

- **FIX**: Fix auto disposal of `Computed` which happened even if `autoDispose` was set to false.

## 2.6.0

- **REFACTOR**: Make auto disposal synchronous.

## 2.5.0

- **FEAT**: Add `run` method to `Computed` to manually trigger an update of its value.
- **FEAT**: Add `run` method to `Effect` to manually re-run the effect.
- **CHORE**: Detect if `Effect` didn't track any reactive value and throw an `EffectWithoutDependenciesError`.

## 2.4.1

- **FIX**: `Signal.lazy` which caused an exception.

## 2.4.0

- **FEAT**: Add `Debouncer` utility class to easily debounce operations and `debounceDelay` to `Resource` to debounce source changes if they fire very often.

## 2.3.0

- **FEAT**: Allow extending signal, computed, resource, list-signal, set-signal and map-signal.

## 2.2.0

- **FEAT**: Add `timeout` parameter to `Signal.until` method to specify a timeout duration. If the condition is not met within the specified duration, the returned future will complete with a `TimeoutException`.

## 2.1.1+1

- **CHORE**: Update `README.md` with new contributors.

## 2.1.1

- **CHORE**: Bump the `alien_signals` dependency to `^0.5.1` for slight performance improvements (thanks to @medz).

## 2.1.0

- **REFACTOR**: Update `alien_signals` dependency from `^0.2.1` to `^0.4.3` with significant performance improvements (thanks to @medz).
- **REFACTOR**: Replace custom reactive node implementations with `alien.ReactiveNode` for better compatibility and performance (thanks to @medz).
- **REFACTOR**: Simplify signal, computed and effect implementations by leveraging new `alien_signals` API (thanks to @medz).
- **PERFORMANCE**: Improve performance by removing redundant tracking operations in the reactive system  (thanks to @medz).
- **FIX**: Add proper cleanup for disposed nodes to prevent memory leaks  (thanks to @medz).
- **FIX**: Fix potential memory leaks in auto-dispose scenarios (thanks to @medz).
- **FIX**: Clear queued flag when running effects in `ReactiveSystem` to ensure proper effect execution (thanks to @medz).
- **CHORE**: Reorder dev_dependencies in pubspec.yaml for improved organization and readability (thanks to @medz).

## 2.0.1

- **FIX**: DevTools extension not working.

## 2.0.0

- **CHORE**: Improve the performance by using `alien_signals` for the reactive system.
- **FEAT**: Expose `untracked`.
- **REFACTOR**: Updated the reactive system from scratch, improving the performances.
- **BREAKING CHANGE**: Remove `set` and `call` methods from Signals (Use an extension to have them back).
- **FEAT**: Add `useRefreshing` to `Resource` to decide whether to update the current state with `isRefreshing` (defaults to true). If you set it to false, when refreshing, the resource will go directly to the loading state.
- **FEAT**: Add `Signal.lazy` to allow the creation of a signal without an initial value. Be aware, the signal will throw an error if you try to read its value before it has been initialized.
- **CHORE**: Remove deprecated `createSignal`, `createComputed`, `createEffect` and `createResource` helpers.
- **CHORE**: Remove `SignalOptions` and `ResourceOptions` classes.
- **FEAT**: Add `batch` function to execute a callback that will not side-effect until its top-most batch is completed. See docs [here](https://solidart.mariuti.com/learning/batch)
- **CHORE**: Add `trackInDevTools` to `SignalOptions` and `ResourceOptions` to disable the DevTools tracking for specific signals and resources, defaults to `SolidartConfig.devToolsEnabled`.

## 2.0.0-dev.6

- **FEAT**: Expose `untracked`.

## 2.0.0-dev.5

- **CHORE**: Improve the performance

## 2.0.0-dev.4

- **REFACTOR**: Updated the reactive system from scratch, improving the performances.
- **BREAKING CHANGE**: Remove `set` and `call` methods from Signals (Use an extension to have them back).
- **FEAT**: Add `useRefreshing` to `Resource` to decide whether to update the current state with `isRefreshing` (defaults to true). If you set it to false, when refreshing, the resource will go directly to the loading state.

## 2.0.0-dev.3

- **FEAT**: Add `Signal.lazy` to allow the creation of a signal without an initial value. Be aware, the signal will throw an error if you try to read its value before it has been initialized.

## 2.0.0-dev.2

- **CHORE**: Remove deprecated `createSignal`, `createComputed`, `createEffect` and `createResource` helpers.
- **CHORE**: Remove `SignalOptions` and `ResourceOptions` classes.

## 2.0.0-dev.1

- **FEAT**: Add `batch` function to execute a callback that will not side-effect until its top-most batch is completed. See docs [here](https://docs.page/nank1ro/solidart~dev/learning/batch)
- **CHORE**: Add `trackInDevTools` to `SignalOptions` and `ResourceOptions` to disable the DevTools tracking for specific signals and resources, defaults to `SolidartConfig.devToolsEnabled`.

## 1.5.4

- **CHORE**: Add `devToolsEnabled` option to manually disable the DevTools extension that defaults to `kDebugMode`

## 1.5.3

- **BUGFIX**: Fix an auto dispose issue of Signals that have some active observations.

## 1.5.2

- **BUGFIX**: Fix DevTools extension with null signal name.

## 1.5.1

- **CHORE**: Upload DevTools extension to pub.dev

## 1.5.0

- **FEAT**: Add DevTools extension to solidart.

## 1.4.1

- **BUGFIX**: The method `didUpdateSignal` of `SolidartObserver` was not triggered for collections.

## 1.4.0

- **FEAT**: Create `SolidartConfig` which you can use to customize the `autoDispose` of all the tracking system and and `observers`.
- **BUGFIX**: Removed the internal `ResourceUnresolved` state so you can easily use the `ResourceState` sealed class.

## 1.3.0

- **FEAT**: Automatic disposal, [see the docs here](https://docs.page/nank1ro/solidart~dev/advanced/automatic-disposal)

## 1.2.2

- **BUGFIX**: Fix the `update` method of a `Resource` that triggered `reportObserved`.

## 1.2.1

- **BUGFIX**: Fix the `updateValue` method of a `Signal` that triggered `reportObserved`. (thanks to @9dan)

## 1.2.0

- **FEAT**: Add 3 new signals: `ListSignal`, `SetSignal` and `MapSignal`. Now you can easily be notified of every change of a list, set or map.
   _Before_:

  ```dart
  final list = Signal([1, 2]);
  // this doesn't work
  list.add(3);
  // instead you have to provide a new list instance
  list.value = [...list, 3];
  ```

  _Now_:

  ```dart
  final list = ListSignal([1, 2]);
  // this now works as expected
  list.add(3);
  ```

- **CHORE**: Rename the `firstWhere` method of a `ReadSignal` into `until`
- **CHORE**: Rename the `firstWhereReady` method of a `Resource` into `untilReady`
- **CHORE**: Rename the `update` method of a `Signal` into `updateValue`
- **CHORE**: Deprecate `createSignal`, `createComputed`, `createEffect` and `createResource`

## 1.1.0

- **BUGFIX**: Fix a bug in the `Resource` where the stream subscription was not disposed correctly

## 1.0.1

Improve `copyWith` methods of `ResourceReady` and `ResourceError`

## 1.0.0+4

Fix the pub.dev pub points.

## 1.0.0+3

Fix the pub.dev pub points.

## 1.0.0+2

Fix the pub.dev pub points.

## 1.0.0+1

Fix the pub.dev pub points.

## 1.0.0

The core of the library has been rewritten in order to support automatic dependency tracking like SolidJS.

- **FEAT**: Add automatic dependency tracking
- **BREAKING CHANGE**: To create derived signals now you should use `createComputed` instead of `signalName.select`
  This allows you to derive from many signals instead of only 1.

  _Before_:

  ```dart
  final count = createSignal(0);
  final doubleCount = count.select((value) => value * 2);
  ```

  _Now_:

  ```dart
  final count = createSignal(0);
  final doubleCount = createComputed(() => count() * 2);
  ```

- **FEAT**: The `createEffect` no longer needs a `signals` array, it automatically track each signal.

  _Before_:

  ```dart
  final effect = createEffect(() {
    print('The counter is now ${counter.value}');
  }, signals: [counter]);
  ```

  _Now_:

  ```dart
  final disposeFn = createEffect((disposeFn) {
    print('The counter is now ${counter.value}');
  })
  ```

- **BREAKING CHANGE**: The `fireImmediately` field on effects has been removed. Now an effect runs immediately by default.
- **FEAT**: Add `observe` method on `Signal`. Use it to easily observe the previous and current value instead of creating an effect.
  ```dart
  final count = createSignal(0);
  final disposeFn = count.observe((previousValue, value) {
    print('The counter changed from $previousValue to $value');
  }, fireImmediately: true);
  ```
- **FEAT**: Add `firstWhere` method on `Signal`. It returns a future that completes when the condition evaluates to true and it returns the current signal value.
  ```dart
  final count = createSignal(0);
  // wait until the count is greater than 5
  final value = await count.firstWhere((value) => value > 5);
  ```
- **FEAT**: Add `firstWhereReady` method on `Resource`. Now you can wait until the resource is ready.
  ```dart
  final resource = createResource(..);
  final data = await resource.firstWhereReady();
  ```
- **FEAT**: The `Resource` now accepts `ResourceOptions`. You can customize the `lazy` value of the resource (defaults to true), if you want your resource to resolve immediately.
- **CHORE**: `ResourceValue` has been renamed into `ResourceState`. Now you can get the state of the resource with the `state` getter.
- **CHORE**: Move `refreshing` from `ResourceWidgetBuilder` into the `ResourceState`. (thanks to @manuel-plavsic)
- **FEAT**: Add `hasPreviousValue` getter to `ReadSignal`. (thanks to @manuel-plavsic)
- **FEAT** Before, only the `fetcher` reacted to the `source`.
Now also the `stream` reacts to the `source` changes by subscribing again to the stream.
In addition, the `stream` parameter of the Resource has been changed from `Stream` into a `Stream Function()` in order to be able to listen to a new stream if it changed.
- **FEAT**: Add the `select` method on the `Resource` class.
The `select` function allows filtering the `Resource`'s data by reading only the properties that you care about.
The advantage is that you keep handling the loading and error states.
- **FEAT**: Make the `Resource` to auto-resolve when accessing its `state`.
- **CHORE**: The `refetch` method of a `Resource` has been renamed to `refresh`.
- **FEAT**: You can decide whether to use `createSignal()` or directly the `Signal()` constructor, now the're equivalent. The same applies to all the other `create` functions.

## 1.0.0-dev8

- **FEAT**: Add the select method on the Resource class.
The select function allows filtering the Resource's data by reading only the properties that you care about.
The advantage is that you keep handling the loading and error states.
- **FEAT**: Make the Resource to auto-resolve when accessing its state

## 1.0.0-dev7

- **CHORE**: `createComputed` now returns a `Computed` class instead of a `ReadSignal`.

## 1.0.0-dev6

- **FEAT** Before, only the `fetcher` reacted to the `source`.
Now also the `stream` reacts to the `source` changes by subscribing again to the stream.
In addition, the `stream` parameter of the Resource has been changed from `Stream` into a `Stream Function()` in order to be able to listen to a new stream if it changed

## 1.0.0-dev5

- **BUGFIX** Refactor the core of the library in order to fix issues with `previousValue` and `hasPreviousValue` of `Computed` and simplify the logic.

## 1.0.0-dev4

- Move `refreshing` from `ResourceWidgetBuilder` into the `ResourceState`. (thanks to @manuel-plavsic)
- Add `hasPreviousValue` getter to `ReadSignal`. (thanks to @manuel-plavsic)

## 1.0.0-dev3

- Deprecate `value` getter in the `Resource`. Use `state` instead.
- Remove `where` method from `ReadSignal`.

## 1.0.0-dev2

- Rename `until` into `firstWhere`
- Rename `untilReady` into `firstWhereReady`
- **FEAT**: add `where` method to `Signal`. It returns a new `ReadSignal` with the values filtered by `condition`.
  Use it to filter the value of another signal, e.g.:

  ```dart
  final loggedInUser = user.where((value) => value != null);
  ```

  The initial value may be null because a `Signal` must always start with an initial value.
  The following values will always satisfy the condition.
  The returned `ReadSignal` will automatically dispose when the parent signal disposes.

## 1.0.0-dev1

This is a development preview of the 1.0.0 release of solidart.
The core of the library has been rewritten in order to support automatic dependency tracking like SolidJS.

- **FEAT**: Add automatic dependency tracking
- **BREAKING CHANGE**: To create derived signals now you should use `createComputed` instead of `signalName.select`
  This allows you to derive from many signals instead of only 1.

  _Before_:

  ```dart
  final count = createSignal(0);
  final doubleCount = count.select((value) => value * 2);
  ```

  _Now_:

  ```dart
  final count = createSignal(0);
  final doubleCount = createComputed(() => count() * 2);
  ```

- **FEAT**: The `createEffect` no longer needs a `signals` array, it automatically track each signal.

  _Before_:

  ```dart
  final effect = createEffect(() {
    print('The counter is now ${counter.value}');
  }, signals: [counter]);
  ```

  _Now_:

  ```dart
  final disposeFn = createEffect((disposeFn) {
    print('The counter is now ${counter.value}');
  })
  ```

- **BREAKING CHANGE**: The `createEffect` method no longer returns an `Effect`, you cannot pause or resume it anymore.
  Instead it returns a `Dispose` callback which you can call when you want to stop it.
  You can also dispose an effect from the inside of the callback.
- **BREAKING CHANGE**: The `fireImmediately` field on effects has been removed. Now an effect runs immediately by default.
- **FEAT**: Add `observe` method on `Signal`. Use it to easily observe the previous and current value instead of creating an effect.
  ```dart
  final count = createSignal(0);
  final disposeFn = count.observe((previousValue, value) {
    print('The counter changed from $previousValue to $value');
  }, fireImmediately: true);
  ```
- **FEAT**: Add `until` method on `Signal`. It returns a future that completes when the condition evaluates to true and it
  returns the current signal value.
  ```dart
  final count = createSignal(0);
  // wait until the count is greater than 5
  final value = await count.until((value) => value > 5);
  ```
- **FEAT**: Add `untilReady` method on `Resource`. Now you can wait until the resource is ready.
  ```dart
  final resource = createResource(..);
  final data = await resource.untilReady();
  ```
- **FEAT**: The `Resource` now accepts `ResourceOptions`. You can customize the `lazy` value of the resource (defaults to true),
  if you want your resource to resolve immediately.
- **CHORE**: `ResourceValue` has been renamed into `ResourceState`. Now you can get the state of the resource with the `state` getter.

## 0.3.0

- **BUGFIX**: Listening to the `source` of a Resource was not stopped when the `source` disposed.
- **BUGFIX**: A `Resource` would not perform the asynchronous operation until someone called the `fetch` method, typically the `ResourceBuilder` widget. This did not apply to the `stream` which was listened to when the resource was created. Now the behaviour has been merged and the `fetch` method has been renamed into `resolve`.
- **CHORE**: Renamed `ReadableSignal` into `ReadSignal`.
- **CHORE**: Renamed the `readable` method of a `Signal` into `toReadSignal()`

## 0.2.4

- Add assert to resource `fetch` method to prevent multiple fetches of the same resource.

## 0.2.3

- The `select` method of a signal now can take a custom `options` parameter to customize its behaviour.
- Fixed an invalid assert in the `ResourceBuilder` widget that happens for resources without a fetcher.

## 0.2.2

- `createResource` now accepts a `stream` and can be used to wrap a Stream and correctly handle its state.

## 0.2.1

- Get a signal value with `signalName()`.

## 0.2.0+1

- Add documentation link inside the pubspec

## 0.2.0

- Documentation improvements
- Refactor Resource, now the `createResource` method takes only 1 generic, the type of the future result.
  ```dart
  // before
  final resource = createResource<SourceValueType, FetcherValueType>(fetcher: fetcher, source: source);
  // now
  final resource = createResource<FetcherValueType>(fetcher: fetcher, source: source); // the FetcherValueType can be inferred by Dart >=2.18.0, so you can omit it
  ```

## 0.1.2

- Add official documentation link
- Fix typo in fireImmediately argument name

## 0.1.1

- Set the minimum Dart SDK version to `2.18`.

## 0.1.0+6

- Update Readme

## 0.1.0+5

- Add code coverage

## 0.1.0+4

- Fix typo in README

## 0.1.0+3

- Decrease minimum Dart version to 2.17.0

## 0.1.0+2

- Remove unused import

## 0.1.0+1

- Fix typos on links

## 0.1.0

- Initial version.
