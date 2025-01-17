import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/models/instantiable_provider.dart';
import 'package:flutter_solidart/src/widgets/provider_scope_override.dart';
import 'package:flutter_solidart/src/widgets/provider_scope_value.dart';
import 'package:solidart/solidart.dart';

part '../models/provider.dart';
part '../models/provider_with_argument.dart';
part '../utils/provider_extensions.dart';

/// {@template provider-scope}
/// Provides [providers] to descendants.
///
/// The Flutter framework works like a Tree. There are ancestors and there are
/// descendants.
///
/// You may incur the need to pass a Signal deep into the tree as a parameter,
/// this is discouraged.
/// You should never pass a signal as a parameter.
///
/// To avoid this there's the _Solid_ widget.
///
/// With this widget you can pass a signal down the tree to anyone who needs it.
///
/// You will have already seen `Theme.of(context)` or `MediaQuery.of(context)`,
/// the procedure is practically the same.
///
/// Let's see an example to grasp the concept.
///
/// You're going to see how to build a toggle theme feature using `Solid`, this example is present also [here](https://docs.page/nank1ro/solidart~dev/examples/toggle-theme)
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Provide the theme mode signal to descendats
///     return ProviderScope(
///       providers: [
///         Provider<Signal<ThemeMode>>(
///           create: () => Signal(ThemeMode.light),
///         ),
///       ],
///       // using the builder method to immediately access the signal
///       builder: (context) {
///         // observe the theme mode value this will rebuild every time the themeMode signal changes.
///         final themeMode = context.observe<Signal<ThemeMode>>().value;
///         return MaterialApp(
///           title: 'Toggle theme',
///           themeMode: themeMode,
///           theme: ThemeData.light(),
///           darkTheme: ThemeData.dark(),
///           home: const MyHomePage(),
///         );
///       },
///     );
///   }
/// }
///
/// class MyHomePage extends StatelessWidget {
///   const MyHomePage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // retrieve the theme mode signal
///     final themeMode = context.get<Signal<ThemeMode>>();
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Toggle theme'),
///       ),
///       body: Center(
///         child:
///             // Listen to the theme mode signal rebuilding only the IconButton
///         SignalBuilder(
///           builder: (_, __) {
///             final mode = themeMode.value;
///             return IconButton(
///               onPressed: () {
///                 // toggle the theme mode
///                 if (mode == ThemeMode.light) {
///                   themeMode.value = ThemeMode.dark;
///                 } else {
///                   themeMode.value = ThemeMode.light;
///                 }
///               },
///               icon: Icon(
///                 mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode
///               ),
///             );
///           },
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
///
/// The `Solid` widgets takes a List of `providers`:
/// The `Provider` has a `create` function that returns the signal.
/// You may create a signal or a derived signal. The value is a Function
/// because the signal is created lazily only when used for the first time, if
/// you never access the signal it never gets created.
/// In the `Provider` you can also specify an identifier for having multiple
/// objects of the same type.
///
/// The `context.get()` method doesn't listen to the signal value. You may use
/// this method inside the `initState` and `build` methods.
///
/// > It is mandatory to set the type to the `Provider` otherwise
/// you're going to encounter an error, for example:
///
/// ```dart
/// Provider<Signal<ThemeMode>>(create: () => Signal(ThemeMode.light))
/// ```
/// , `context.observe<Signal<ThemeMode>>` and `context.get<Signal<ThemeMode>>`
/// where `Signal<ThemeMode>` is the type of signal with its type value.
///
/// ## Providers
///
/// You can also pass `Provider`s to descendants:
///
/// ```dart
/// class NameProvider {
///   const NameProvider(this.name);
///   final String name;
///
///   void dispose() {
///     // put your dispose logic here
///     // ignore: avoid_print
///     print('dispose name provider');
///   }
/// }
///
/// class NumberProvider {
///   const NumberProvider(this.number);
///   final int number;
/// }
///
/// class ProvidersPage extends StatelessWidget {
///   const ProvidersPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Providers'),
///       ),
///       body: ProviderScope(
///         providers: [
///           Provider<NameProvider>(
///             create: () => const NameProvider('Ale'),
///             // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
///             dispose: (provider) => provider.dispose(),
///           ),
///           Provider<NumberProvider>(
///             create: () => const NumberProvider(1),
///             // Do not create the provider lazily, but immediately
///             lazy: false,
///             id: 1,
///           ),
///           Provider<NumberProvider>(
///             create: () => const NumberProvider(10),
///             id: 2,
///           ),
///         ],
///         child: const SomeChildThatNeedsProviders(),
///       ),
///     );
///   }
/// }
///
/// class SomeChildThatNeedsProviders extends StatelessWidget {
///   const SomeChildThatNeedsProviders({super.key});
///   @override
///   Widget build(BuildContext context) {
///     final nameProvider = context.get<NameProvider>();
///     final numberProvider = context.get<NumberProvider>(1);
///     final numberProvider2 = context.get<NumberProvider>(2);
///     return Center(
///       child: Column(
///         crossAxisAlignment: CrossAxisAlignment.center,
///         children: [
///           Text('name: ${nameProvider.name}'),
///           const SizedBox(height: 8),
///           Text('number: ${numberProvider.number}'),
///           const SizedBox(height: 8),
///           Text('number2: ${numberProvider2.number}'),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// You can have multiple providers of the same type in the same Solid widget
/// specifying a different id to each one.
///
/// ## Solid.value
///
/// The `Solid.value` factory is useful for passing `providers`
/// to modals, because they are spawned in a new tree.
/// This is necessary because modals are spawned in a new tree.
/// `Solid.value` takes a list of `ProviderElement`s.
///
/// ### Access providers in modals
///
/// ```dart
/// Future<void> openDialog(BuildContext context) {
///    return showDialog(
///      context: context,
///      builder: (_) =>
///       // using `Solid.value` we provide the existing provider(s) to the dialog
///       ProviderScope.value(
///        elements: [
///          context.getElement<NameProvider>(),
///          context.getElement<NumberProvider>(ProviderId.firstNumber),
///          context.getElement<NumberProvider>(ProviderId.secondNumber),
///        ],
///        child: Dialog(
///          child: Builder(builder: (innerContext) {
///            final nameProvider = innerContext.get<NameProvider>();
///            final numberProvider1 =
///                innerContext.get<NumberProvider>(ProviderId.firstNumber);
///            final numberProvider2 =
///                innerContext.get<NumberProvider>(ProviderId.secondNumber);
///            return SizedBox.square(
///              dimension: 100,
///              child: Center(
///                child: Text('''
///  name: ${nameProvider.name}
///  number1: ${numberProvider1.number}
///  number2: ${numberProvider2.number}
///  '''),
///             ),
///           );
///         }),
///       ),
///     ),
///   );
/// }
/// ```
/// {@endtemplate}
@immutable
class ProviderScope extends StatefulWidget {
  /// {@macro provider-scope}
  const ProviderScope({
    super.key,
    this.child,
    required this.providers,
    this.builder,
  });

  /// {@macro ProviderScopeValue}
  static ProviderScopeValue value({
    Key? key,
    required BuildContext mainContext,
    Widget? child,
    TransitionBuilder? builder,
  }) {
    return ProviderScopeValue(
      key: key,
      mainContext: mainContext,
      child: _ProviderWidgetBuilder(builder: builder, child: child),
    );
  }

  /// {@template ProviderScope.child}
  /// The widget child that gets access to the [providers].
  ///
  /// NOTE: If you also provide a [builder], the [child] will be passed to the
  /// builder to optimize rebuilds, but won't have access to the providers.
  /// {@endtemplate}
  final Widget? child;

  /// The widget builder that gets access to the [providers].
  final TransitionBuilder? builder;

  /// All the providers provided to all the descendants of [ProviderScope].
  final List<InstantiableProvider> providers;

  @override
  State<ProviderScope> createState() => ProviderScopeState();

  /// Finds the first SolidState ancestor that satisfies the given [id].
  static ProviderScopeState? _findState<T extends Object>(
    BuildContext context, {
    required Provider<T> id,
  }) {
    // try finding the solid override first
    final solidOverride = ProviderScopeOverride.maybeOf(context);
    if (solidOverride != null) {
      final state = solidOverride.solidState;
      if (state.isProviderInScope<T>(id)) return state;
    }

    return _InheritedProvider.inheritFromNearest<T>(context, id, null)?.state;
  }

  /// Tries to find a provider of type T from the created providers and returns
  /// it.
  ///
  /// The provider is created in case the find fails.
  /// If the provider is not found in any ProviderScope, it returns null.
  static T? _getOrCreateProvider<T extends Object>(
    BuildContext context, {
    required Provider<T> id,
  }) {
    // If there is a ProviderValue ancestor, use it as the context
    final providerScopeValueContext = ProviderScopeValue.maybeOf(context);
    final effectiveContext = providerScopeValueContext ?? context;
    final state = _findState<T>(effectiveContext, id: id);
    if (state == null) return null;
    final createdProvider = state._createdProviders[(id: id, type: T)];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProvider<T>(id);
  }

  /// Finds the first SolidState ancestor that satisfies the given [id].
  static ProviderScopeState? _findStateArgProvider<T extends Object, A>(
    BuildContext context, {
    required ArgProvider<T, A> id,
  }) {
    // try finding the solid override first
    final solidOverride = ProviderScopeOverride.maybeOf(context);
    if (solidOverride != null) {
      final state = solidOverride.solidState;
      if (state.isArgProviderInScope<T, A>(id)) return state;
    }

    return _InheritedProvider.inheritFromNearest<T>(context, null, id)?.state;
  }

  /// Tries to find a provider of type T from the created providers and returns
  /// it.
  ///
  /// The provider is created in case the find fails.
  /// If the provider is not found in any ProviderScope, it returns null.
  static T? _getOrCreateArgProvider<T extends Object, A>(
    BuildContext context, {
    required ArgProvider<T, A> id,
  }) {
    // If there is a ProviderValue ancestor, use it as the context
    final providerScopeValueContext = ProviderScopeValue.maybeOf(context);
    final effectiveContext = providerScopeValueContext ?? context;
    final state = _findStateArgProvider<T, A>(effectiveContext, id: id);
    if (state == null) return null;
    final providerAsId = state._allArgProvidersInScope[(type: T, id: id)];
    final createdProvider =
        state._createdProviders[(type: T, id: providerAsId)];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProviderForArgProvider<T, A>(id);
  }
}

/// The state of the [ProviderScope] widget
class ProviderScopeState extends State<ProviderScope> {
  /// Stores all the argument providers in the current scope. The values are
  /// used as internal IDs by [_createdProviders].
  final _allArgProvidersInScope = HashMap<
      ({Type type, ArgProvider<dynamic, dynamic> id}), Provider<dynamic>>();

  /// Stores all the providers in the current scope. The values are
  /// used as internal IDs by [_createdProviders].
  final _allProvidersInScope =
      HashMap<({Type type, Provider<dynamic> id}), Provider<dynamic>>();

  // Stores all the created providers.
  // The key is the provider, while the value is its value.
  final _createdProviders =
      HashMap<({Type type, Provider<dynamic> id}), Object?>();

  // Stores all the disposeFn for each signal
  final _signalDisposeCallbacks = <DisposeEffect>[];

  @override
  void initState() {
    super.initState();

    final providers = widget.providers.whereType<Provider<Object>>().toList();

    assert(
      () {
        // check if the provider type is not dynamic
        // check if there are multiple providers of the same type
        final ids = <Provider<Object>>[];
        for (final provider in providers) {
          final id = provider; // the instance of the provider
          if (ids.contains(id)) {
            throw MultipleProviderOfSameInstance();
          }
          ids.add(id);
        }
        return true;
      }(),
      '',
    );

    for (final provider in providers) {
      final key = (type: provider._valueType, id: provider);
      _allProvidersInScope[key] = provider;

      // create non lazy providers.
      if (!provider._lazy) {
        // create and store the provider
        _createdProviders[key] = provider._create(context);
      }
    }

    final argProviderInits =
        widget.providers.whereType<ArgProviderInit<Object, dynamic>>().toList();

    assert(
      () {
        // check if the provider type is not dynamic
        // check if there are multiple providers of the same type
        final ids = <ArgProvider<Object, dynamic>>[];
        for (final provider in argProviderInits) {
          final id = provider._argProvider; // the instance of the provider
          if (ids.contains(id)) {
            throw MultipleProviderOfSameInstance();
          }
          ids.add(id);
        }
        return true;
      }(),
      '',
    );

    for (final argProviderInit in argProviderInits) {
      final key = (
        type: argProviderInit._argProvider._valueType,
        id: argProviderInit._argProvider,
      );
      _allArgProvidersInScope[key] =
          argProviderInit._argProvider._generateProvider(argProviderInit._arg);

      // create non lazy providers.
      if (!argProviderInit._argProvider._lazy) {
        // create and store the provider
        final complexKey = (
          type: argProviderInit._argProvider._valueType,
          id: _allArgProvidersInScope[key]!,
        );
        _createdProviders[complexKey] =
            _allArgProvidersInScope[key]!._create(context);
      }
    }
  }

  @override
  void dispose() {
    // stop listening to signals and dispose all of them if needed
    for (final disposeFn in _signalDisposeCallbacks) {
      disposeFn();
    }

    // dispose all the created providers
    _createdProviders.forEach((key, value) {
      _allProvidersInScope[key]?._disposeFn(context, value);
    });

    _signalDisposeCallbacks.clear();
    _allArgProvidersInScope.clear();
    _allProvidersInScope.clear();
    _createdProviders.clear();
    super.dispose();
  }

  /// -- Providers logic

  /// Try to find a [Provider] of type <T> or [id] and returns it
  Provider<T>? _getProvider<T extends Object>(Provider<T> id) {
    return _allProvidersInScope[(type: T, id: id)] as Provider<T>?;
  }

  /// Creates a provider of type T and stores it
  T createProvider<T extends Object>(Provider<T> id) {
    // find the provider in the list
    final provider = _getProvider<T>(id)!;
    // create and return it
    final value = provider._create(context);
    // store the created provider
    _createdProviders[(type: T, id: id)] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isProviderInScope<T extends Object>(Provider<T> id) {
    // Find the provider by type
    return _getProvider<T>(id) != null;
  }

  /// -- ArgProviders logic

  /// Try to find a [Provider] of type <T> or [id] and returns it
  Provider<T>? _getProviderForArgProvider<T extends Object, A>(
    ArgProvider<T, A> id,
  ) {
    return _allArgProvidersInScope[(type: T, id: id)] as Provider<T>?;
  }

  /// Creates a provider of type T and stores it.
  T createProviderForArgProvider<T extends Object, A>(ArgProvider<T, A> id) {
    // find the provider in the list
    final provider = _getProviderForArgProvider<T, A>(id)!;
    // create and return it
    final value = provider._create(context);
    // store the created provider
    _createdProviders[(
      type: T,
      id: _allArgProvidersInScope[(type: T, id: id)]!,
    )] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isArgProviderInScope<T extends Object, A>(ArgProvider<T, A> id) {
    return _getProviderForArgProvider<T, A>(id) != null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(
      state: this,
      child: _ProviderWidgetBuilder(
        builder: widget.builder,
        child: widget.child,
      ),
    );
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IterableProperty('createdProviders', _createdProviders.values),
    );
  }

  // coverage:ignore-end
}

@immutable
class _InheritedProvider extends InheritedModel<Object> {
  const _InheritedProvider({required this.state, required super.child});

  final ProviderScopeState state;

  @override
  bool updateShouldNotify(covariant _InheritedProvider oldWidget) {
    return false;
  }

  bool isSupportedAspectWithType<T extends Object>(
    Provider<T>? providerId,
    ArgProvider<T, dynamic>? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );
    if (providerId != null) {
      return state.isProviderInScope<T>(providerId);
    }
    return state.isArgProviderInScope<T, dynamic>(argProviderId!);
  }

  bool isSupportedAspectWithTypeArg<T extends Object>(
    ArgProvider<T, dynamic> id,
  ) {
    return state.isArgProviderInScope<T, dynamic>(id);
  }

  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedProvider oldWidget,
    Set<dynamic> dependencies,
  ) {
    return false;
  }

  // The following two methods are taken from [InheritedModel] and modified
  // in order to find the first [_InheritedSolid] ancestor that contains the
  // searched Signal id [aspect] or provider of type [ProviderType].
  // This is a small opmitization that avoids traversing all the [Solid]
  // ancestors.
  // The [result] will be a single _InheritedSolid of context's type T ancestor
  // that supports the specified model [aspect].
  static InheritedElement? _findNearestModel<T extends Object>(
    BuildContext context,
    Provider<T>? providerId,
    ArgProvider<T, dynamic>? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );
    final model =
        context.getElementForInheritedWidgetOfExactType<_InheritedProvider>();
    // No ancestors of type T found, exit.
    if (model == null) {
      return null;
    }

    assert(
      model.widget is _InheritedProvider,
      'The widget must be of type _InheritedProvider',
    );
    final modelWidget = model.widget as _InheritedProvider;

    // The model contains the aspect, the ancestor has been found, return it.
    if (modelWidget.isSupportedAspectWithType<T>(providerId, argProviderId)) {
      return model;
    }

    // The aspect has not been found in the current ancestor, go up to other
    // ancestors and try to find it.
    Element? modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    // Return null if we've reached the root.
    if (modelParent == null) {
      return null;
    }

    return _findNearestModel<T>(modelParent!, providerId, argProviderId);
  }

  /// Makes [context] dependent on the specified [providerId] of an
  /// [_InheritedProvider]
  ///
  /// The dependencies created by this method target the nearest
  /// [_InheritedProvider] ancestor which [isSupportedAspect]  returns true.
  ///
  /// If no ancestor of type T exists, null is returned.
  static _InheritedProvider? inheritFromNearest<T extends Object>(
    BuildContext context,
    Provider<T>? providerId,
    ArgProvider<T, dynamic>? argProviderId,
  ) {
    assert(
      (providerId != null) ^ (argProviderId != null),
      'Either a Provider or an ArgProvider must be used as ID.',
    );

    // Try and find a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel<T>(context, providerId, argProviderId);
    if (model == null) {
      return null;
    }

    return model.widget as _InheritedProvider;
  }
}

/// {@template ArgProviderWithoutScopeError}
/// Error thrown when the [Provider] was never attached to a [ProviderScope].
/// {@endtemplate}
class ProviderWithoutScopeError extends Error {
  /// {@macro ArgProviderWithoutScopeError}
  ProviderWithoutScopeError(this.provider);

  // ignore: public_member_api_docs
  final Provider<dynamic> provider;

  @override
  String toString() {
    return 'Seems like that you forgot to provide the argument-less provider '
        'of type ${provider._valueType} to a ProviderScope.';
  }
}

/// {@template Providermultipleproviderofsametypeerror}
/// Error thrown when multiple providers of the same instance are created
/// together.
/// {@endtemplate}
class MultipleProviderOfSameInstance extends Error {
  /// {@macro Providermultipleproviderofsametypeerror}
  MultipleProviderOfSameInstance();

  @override
  String toString() {
    return '''
      You cannot create or inject multiple providers of the same instance together.
      ''';
  }
}

/// {@template ArgProviderWithoutScopeError}
/// Error thrown when the [ArgProvider] was never attached to a [ProviderScope].
/// {@endtemplate}
class ArgProviderWithoutScopeError extends Error {
  /// {@macro ArgProviderWithoutScopeError}
  ArgProviderWithoutScopeError(this.argProvider);

  // ignore: public_member_api_docs
  final ArgProvider<dynamic, dynamic> argProvider;

  @override
  String toString() {
    return 'Seems like that you forgot to provide the provider of type'
        '${argProvider._valueType} and argument type '
        '${argProvider._argumentType} to a ProviderScope.';
  }
}

class _ProviderWidgetBuilder extends StatelessWidget {
  const _ProviderWidgetBuilder({
    this.child,
    this.builder,
  });

  final TransitionBuilder? builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null && builder == null) {
      return child!;
    }
    return builder!(context, child);
  }
}
