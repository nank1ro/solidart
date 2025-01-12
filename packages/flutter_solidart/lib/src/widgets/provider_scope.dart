import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/widgets/provider_scope_override.dart';
import 'package:flutter_solidart/src/widgets/provider_scope_value.dart';
import 'package:solidart/solidart.dart';

part '../models/provider.dart';
part '../models/provider_with_argument.dart';
part '../models/provider_extensions.dart';
part '../utils/maybe_provider.dart';

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
/// The `context.observe()` method listen to the signal value and rebuilds the
/// widget when the value changes. It takes an optional `id` that is the signal
/// identifier that you want to use. This method must be called only inside the
/// `build` method.
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
      child: _ProviderWidgetBuilder(
        builder: builder,
        child: child,
      ),
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
  final List<Provider<dynamic>> providers;

  @override
  State<ProviderScope> createState() => ProviderScopeState();

  /// Finds the first SolidState ancestor that satisfies the given [id].
  ///
  /// If [listen] is true, the [context] gets subscribed to the given value.
  static ProviderScopeState? _findState<T>(
    BuildContext context, {
    required Provider<T> id,
    bool listen = false,
  }) {
    // try finding the solid override first
    final solidOverride = ProviderScopeOverride.maybeOf(context);
    if (solidOverride != null) {
      final state = solidOverride.solidState;
      if (state.isProviderInScope<T>(id)) return state;
    }

    return _InheritedProvider.inheritFromNearest<T>(
      context,
      id,
      listen: listen,
    )?.state;
  }

  /// Tries to find a provider of type T from the created providers and returns
  /// it.
  ///
  /// The provider is created in case the find fails.
  /// If the provider is not found in any ProviderScope, it returns null.
  static MaybeProvidedValue<T> _getOrCreateProvider<T>(
    BuildContext context, {
    required Provider<T> id,
    bool listen = false,
  }) {
    // If there is a ProviderValue ancestor, use it as the context
    final providerScopeValueContext = ProviderScopeValue.maybeOf(context);
    final effectiveContext = providerScopeValueContext ?? context;
    final state = _findState<T>(
      effectiveContext,
      id: id,
      listen: listen,
    );
    if (state == null) return ProviderNotFound<T>._();
    final createdProvider = state._createdProviders[(id: id, type: T)];
    if (createdProvider != null) {
      return ProvidedValue._(createdProvider as T);
    }
    // if the provider is not already present, create it lazily
    return ProvidedValue._(state.createProvider<T>(id));
  }
}

/// The state of the [ProviderScope] widget
class ProviderScopeState extends State<ProviderScope> {
  /// Stores all the providers in the current scope
  final _allProvidersInScope =
      HashMap<({Type type, Provider<dynamic> id}), Provider<dynamic>>();

  // Stores all the created providers.
  // The key is the provider, while the value is its value.
  final _createdProviders =
      HashMap<({Type type, Provider<dynamic> id}), Object?>();

  // Stores all the disposeFn for each signal
  final _signalDisposeCallbacks = <DisposeEffect>[];
  Provider<dynamic>? _changedDependency;
  int _dependenciesVersion = 0;

  @override
  void initState() {
    super.initState();

    assert(
      () {
        // check if the provider type is not dynamic
        // check if there are multiple providers of the same type
        final ids = <Provider<dynamic>>[];
        for (final provider in widget.providers) {
          final id = provider; // the instance of the provider
          if (id._valueType == dynamic) throw ProviderDynamicError();

          if (ids.contains(id)) {
            throw MultipleProviderOfSameInstance(id);
          }
          ids.add(id);
        }
        return true;
      }(),
      '',
    );

    for (final provider in widget.providers) {
      final key = (id: provider, type: provider._valueType);
      _allProvidersInScope[key] = provider;

      // create non lazy providers.
      if (!provider.lazy) {
        // create and store the provider
        _createdProviders[key] = provider._create(context);
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
      _allProvidersInScope[key]!._disposeFn(context, value);
    });

    _signalDisposeCallbacks.clear();
    _allProvidersInScope.clear();
    _createdProviders.clear();
    super.dispose();
  }

  /// -- Signals logic
  void _initializeSignal<S extends SignalBase<dynamic>>(
    S signal, {
    required Provider<S> id,
  }) {
    final unobserve = signal.observe((_, value) {
      setState(() {
        _changedDependency = id;
        _dependenciesVersion++;
      });
    });
    signal.onDispose(unobserve);
    _signalDisposeCallbacks.add(unobserve);
  }

  /// -- Providers logic

  /// Try to find a [Provider] of type <T> or [id] and returns it
  Provider<T>? _getProvider<T>(Provider<T> id) {
    return _allProvidersInScope[(type: T, id: id)] as Provider<T>?;
  }

  /// Creates a provider of type T and stores it
  T createProvider<T>(Provider<T> id) {
    // find the provider in the list
    final provider = _getProvider<T>(id)!;
    // create and return it
    final value = provider._create(context);
    if (provider._isSignal) {
      _initializeSignal<SignalBase<dynamic>>(
        value as SignalBase,
        id: id as Provider<SignalBase<dynamic>>,
      );
    }

    // store the created provider
    _createdProviders[(type: T, id: id)] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isProviderInScope<T>(Provider<T> id) {
    // Find the provider by type
    return _getProvider<T>(id) != null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(
      state: this,
      dependenciesVersion: _dependenciesVersion,
      changedDependency: _changedDependency,
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
  const _InheritedProvider({
    required this.state,
    required this.changedDependency,
    required this.dependenciesVersion,
    required super.child,
  });

  final ProviderScopeState state;
  final Provider<dynamic>? changedDependency;
  final int dependenciesVersion;

  @override
  bool updateShouldNotify(covariant _InheritedProvider oldWidget) {
    return oldWidget.dependenciesVersion != dependenciesVersion;
  }

  bool isSupportedAspectWithType<T>(Provider<T> id) {
    return state.isProviderInScope<T>(id);
  }

  /// Fine-grained rebuilding of signals that changed value
  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedProvider oldWidget,
    Set<dynamic> dependencies,
  ) {
    return dependencies.contains(changedDependency);
  }

  // The following two methods are taken from [InheritedModel] and modified
  // in order to find the first [_InheritedSolid] ancestor that contains the
  // searched Signal id [aspect] or provider of type [ProviderType].
  // This is a small opmitization that avoids traversing all the [Solid]
  // ancestors.
  // The [result] will be a single _InheritedSolid of context's type T ancestor
  // that supports the specified model [aspect].
  static InheritedElement? _findNearestModel<T>(
    BuildContext context,
    Provider<T> id,
  ) {
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
    if (modelWidget.isSupportedAspectWithType<T>(id)) {
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

    return _findNearestModel<T>(modelParent!, id);
  }

  /// Makes [context] dependent on the specified [id] of an
  /// [_InheritedProvider]
  ///
  /// When the given [id] of the model changes, the [context] will be
  /// rebuilt if [listen] is set to true.
  ///
  /// The dependencies created by this method target the nearest
  /// [_InheritedProvider] ancestor which [isSupportedAspect]  returns true.
  ///
  /// If [id] is null this method is the same as
  /// `context.dependOnInheritedWidgetOfExactType<T>()` if [listen] is true,
  /// otherwise it's a simple
  /// `context.getElementForInheritedWidgetOfExactType<T>()`.
  ///
  /// If no ancestor of type T exists, null is returned.
  static _InheritedProvider? inheritFromNearest<T>(
    BuildContext context,
    Provider<T> id, {
    // Whether to listen to the [InheritedModel], defaults to false.
    bool listen = false,
  }) {
    // Try finding a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel<T>(context, id);
    if (model == null) {
      return null;
    }

    // depend on the inherited element if [listen] is true
    if (listen) {
      context.dependOnInheritedElement(model, aspect: id) as _InheritedProvider;
    }

    return model.widget as _InheritedProvider;
  }
}

/// {@template providererror}
/// Error thrown when a [Provider] cannot be found.
/// {@endtemplate}
class ProviderError extends Error {
  /// {@macro providererror}
  ProviderError();

  @override
  String toString() {
    return '''
Error: could not find a ProviderScope containing the injected provider.
To fix, please:
          
  * Be sure to have a ProviderScope ancestor specifying the correct provider.
    * The context used must be a descendant.
  * Ensure you injected the right provider.
  
If none of these solutions work, please file a bug at:
https://github.com/nank1ro/solidart/issues/new
      ''';
  }
}

/// Error thrown when the [Provider] has a `dynamic` Type.
class ProviderDynamicError extends Error {
  @override
  String toString() {
    return '''
    Seems like that you forgot to declare the provider type.
    You have `Provider()` but it should be `Provider<ProviderType>()`.
      ''';
  }
}

/// {@template Providermultipleproviderofsametypeerror}
/// Error thrown when multiple providers of the same [provider] are created
/// together.
/// {@endtemplate}
class MultipleProviderOfSameInstance extends Error {
  /// {@macro Providermultipleproviderofsametypeerror}
  MultipleProviderOfSameInstance(this.provider);

  // ignore: public_member_api_docs
  final Provider<dynamic> provider;

  @override
  String toString() {
    return '''
      You cannot create or inject multiple providers with the same Provider instance together.
      Provider type: ${provider._valueType}
      ''';
  }
}

/// Error thrown when the [Provider] was never attached to a [ProviderScope].
class ProviderWithoutScopeError extends Error {
  /// {@macro Providermultipleproviderofsametypeerror}
  ProviderWithoutScopeError(this.provider);

  // ignore: public_member_api_docs
  final ArgProvider<dynamic, dynamic> provider;

  @override
  String toString() {
    return '''
    Seems like that you forgot to provide the provider ${provider._valueType} and argument ${provider._argumentType} to a ProviderScope.
      ''';
  }
}

class _ProviderWidgetBuilder extends StatelessWidget {
  const _ProviderWidgetBuilder({
    this.child,
    this.builder,
  }) : assert(
          (builder != null) || (child != null),
          'Provide a child or a builder',
        );

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
