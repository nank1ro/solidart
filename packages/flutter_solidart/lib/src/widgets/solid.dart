import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/widgets/solid_override.dart';
import 'package:solidart/solidart.dart';

part '../models/solid_element.dart';
part '../models/provider_id.dart';

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
  const ProviderScope({super.key, this.child, this.providers = const []})
      : builder = null,
        _canAutoDisposeProviders = true;

  /// {@macro provider-scope}
  const ProviderScope.builder({
    super.key,
    this.builder,
    this.providers = const [],
  })  : child = null,
        _canAutoDisposeProviders = true;

  /// Private constructor used internally to hide the `autoDispose` field
  const ProviderScope._valueInternal({
    required super.key,
    required this.providers,
    required this.child,
    required this.builder,
    required bool autoDispose,
  })  : assert(
          (child != null) ^ (builder != null),
          'Provide either a child or a builder',
        ),
        _canAutoDisposeProviders = autoDispose;

  /// Provide a single [Provider] to a new route.
  ///
  /// This is useful for passing multiple providers to modals, because are
  /// spawned in a new tree.
  factory ProviderScope.value({
    Key? key,
    required BuildContext mainTreeContext,
    required ProviderId<dynamic> providerId,
    required Widget child,
  }) {
    return ProviderScope._valueInternal(
      key: key,
      providers: [providerId._getProvider(mainTreeContext)],
      autoDispose: false,
      builder: null,
      child: child,
    );
  }

  /// Provide multiple [Provider]s to a new route.
  ///
  /// This is useful for passing multiple providers to modals, because are
  /// spawned in a new tree.
  factory ProviderScope.values({
    Key? key,
    required BuildContext mainTreeContext,
    required List<ProviderId<dynamic>> providerIds,
    required Widget child,
  }) {
    return ProviderScope._valueInternal(
      key: key,
      providers:
          providerIds.map((id) => id._getProvider(mainTreeContext)).toList(),
      autoDispose: false,
      builder: null,
      child: child,
    );
  }

  /// The widget child that gets access to the [providers].
  final Widget? child;

  /// The widget builder that gets access to the [providers].
  final WidgetBuilder? builder;

  /// All the providers provided to all the descendants of [ProviderScope].
  final List<Provider<dynamic>> providers;

  /// By default signals and providers are going to be auto-disposed when the
  ///  Solid widget disposes.
  /// When using Solid.value this is not wanted because the signals and
  /// providers are already managed by another Solid widget.
  final bool _canAutoDisposeProviders;

  @override
  State<ProviderScope> createState() => ProviderScopeState();

  /// Finds the first SolidState ancestor that satisfies the given [id].
  ///
  /// If [listen] is true, the [context] gets subscribed to the given value.
  static ProviderScopeState _findState<T>(
    BuildContext context, {
    required ProviderId<T> id,
    bool listen = false,
  }) {
    // try finding the solid override first
    final solidOverride = SolidOverride.maybeOf(context);
    if (solidOverride != null) {
      final state = solidOverride.solidState;
      if (state.isProviderInScope<T>(id)) return state;
    }

    final state = _InheritedProvider.inheritFromNearest<T>(
      context,
      id,
      listen: listen,
    )?.state;
    if (state == null) throw ProviderError<T>(id);
    return state;
  }

  /// {@template provider-scope.get}
  /// Obtains the Provider of the given type T and [id] corresponding to the
  /// nearest [ProviderScope] widget.
  ///
  /// Throws if no such element or [ProviderScope] widget is found.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  /// {@endtemplate}
  static T get<T>(BuildContext context, ProviderId<T> id) {
    return _getOrCreateProvider<T>(context, id: id);
  }

  /// {@template provider-scope.maybeGet}
  /// Tries to obtain the Provider of the given type T and [id] corresponding to
  /// the nearest [ProviderScope] widget.
  ///
  /// Throws if no such element or [ProviderScope] widget is found.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  /// {@endtemplate}
  static T? maybeGet<T>(BuildContext context, ProviderId<T> id) {
    try {
      return _getOrCreateProvider<T>(context, id: id);
    } catch (e) {
      if (e is ProviderError<T>) {
        return null;
      }
      rethrow;
    }
  }

  /// {@template provider-scope.getElement}
  /// Obtains the SolidElement of a Provider of the given type T and [id]
  /// corresponding to the nearest [ProviderScope] widget.
  ///
  /// Throws if no such element or [ProviderScope] widget is found.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  /// {@endtemplate}
  static Provider<T> _getProvider<T>(
    BuildContext context,
    ProviderId<T> id,
  ) {
    final state = _findState<T>(context, id: id);
    return state._getProvider<T>(id)!;
  }

  /// {@template provider-scope.observe}
  /// Subscribe to the [Signal] of the given value type and [id] corresponding
  /// to the nearest [ProviderScope] widget rebuilding the widget when the value
  /// exposed by the [Signal] changes.
  ///
  /// Throws if no such element or [ProviderScope] widget is found.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Listens to the signal so it causes the widget to rebuild.
  ///
  /// You must call this method only from the `build` method.
  ///
  /// WARNING: Doesn't support observing a Resource.
  /// {@endtemplate}
  static T observe<T extends SignalBase<dynamic>>(
    BuildContext context,
    ProviderId<T> id,
  ) {
    return _getOrCreateProvider<T>(context, id: id, listen: true);
  }

  /// {@template provider-scope.update}
  /// Convenience method to update a `Signal` value.
  ///
  /// You can use it to update a signal value, e.g:
  /// ```dart
  /// const myCounter = ProviderId<Signal<int>>();
  ///
  /// // some function inside some widget
  /// someFn(BuildContext context) {
  ///   context.update(myCounter, (value) => value * 2);
  /// }
  /// ```
  /// This is equal to:
  /// ```dart
  /// // retrieve the signal
  /// final signal = context.get(myCounter);
  /// // update the signal
  /// signal.update((value) => value * 2);
  /// ```
  /// but shorter when you don't need the signal for anything else.
  ///
  /// WARNING: Supports only the `Signal` type
  /// {@endtemplate}
  static void update<T>(
    BuildContext context,
    T Function(T value) callback,
    ProviderId<Signal<T>> id,
  ) {
    // retrieve the signal and update its value
    get<Signal<T>>(context, id).updateValue(callback);
  }

  /// Tries to find a provider of type T from the created providers and returns
  /// it.
  ///
  /// The provider is created in case the find fails.
  static T _getOrCreateProvider<T>(
    BuildContext context, {
    required ProviderId<T> id,
    bool listen = false,
  }) {
    final state = _findState<T>(context, id: id, listen: listen);
    final createdProvider = state._createdProviders[(id: id, type: T)];
    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProvider<T>(id);
  }
}

/// The state of the [ProviderScope] widget
class ProviderScopeState extends State<ProviderScope> {
  /// Stores all the providers in the current scope
  final _allProvidersInScope =
      HashMap<({Type type, ProviderId<dynamic> id}), Provider<dynamic>>();

  // Stores all the created providers.
  // The key is the provider, while the value is its value.
  final _createdProviders =
      HashMap<({Type type, ProviderId<dynamic> id}), Object?>();

  // Stores all the disposeFn for each signal
  final _signalDisposeCallbacks = <DisposeEffect>[];
  ProviderId<dynamic>? _changedDependency;
  int _dependenciesVersion = 0;

  @override
  void initState() {
    super.initState();

    assert(
      () {
        // check if the provider type is not dynamic
        // check if there are multiple providers of the same type
        final ids = <ProviderId<dynamic>>[];
        for (final provider in widget.providers) {
          final id = provider.id;
          if (id._valueType == dynamic) throw ProviderDynamicError();

          if (ids.contains(id)) {
            throw ProviderMultipleProviderOfSameTypeError(
              providerType: id._valueType,
              id: id,
            );
          }
          ids.add(id);
        }
        return true;
      }(),
      '',
    );

    for (final provider in widget.providers) {
      final key = (id: provider.id, type: provider.id._valueType);
      _allProvidersInScope[key] = provider;

      // todo: check if injected providers with ProviderScope.value/values get initialized again...
      // create non lazy providers.
      if (!provider.lazy) {
        // create and store the provider
        _createdProviders[key] = provider._init();
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
    if (widget._canAutoDisposeProviders) {
      _createdProviders.forEach((key, value) {
        _allProvidersInScope[key]!._disposeFn(context, value);
      });
    }

    _signalDisposeCallbacks.clear();
    _allProvidersInScope.clear();
    _createdProviders.clear();
    super.dispose();
  }

  /// -- Signals logic
  void _initializeSignal<S extends SignalBase<dynamic>>(
    S signal, {
    required ProviderId<S> id,
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
  Provider<T>? _getProvider<T>(ProviderId<T> id) {
    return _allProvidersInScope[(type: T, id: id)] as Provider<T>?;
  }

  /// Creates a provider of type T and stores it
  T createProvider<T>(ProviderId<T> id) {
    // find the provider in the list
    final provider = _getProvider<T>(id)!;
    // create and return it
    final value = provider._init();
    if (provider._isSignal) {
      _initializeSignal<SignalBase<dynamic>>(
        value as SignalBase,
        id: id as ProviderId<SignalBase<dynamic>>,
      );
    }

    // store the created provider
    _createdProviders[(type: T, id: id)] = value;
    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isProviderInScope<T>(ProviderId<T> id) {
    // Find the provider by type
    return _getProvider<T>(id) != null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(
      state: this,
      dependenciesVersion: _dependenciesVersion,
      changedDependency: _changedDependency,
      child: widget.builder != null
          ? Builder(builder: (context) => widget.builder!(context))
          : widget.child!,
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
  final ProviderId<dynamic>? changedDependency;
  final int dependenciesVersion;

  @override
  bool updateShouldNotify(covariant _InheritedProvider oldWidget) {
    return oldWidget.dependenciesVersion != dependenciesVersion;
  }

  bool isSupportedAspectWithType<T>(ProviderId<T> id) {
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
    ProviderId<T> id,
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
    ProviderId<T> id, {
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
/// Error thrown when the [Provider] of type [id] cannot be found
/// {@endtemplate}
class ProviderError<T> extends Error {
  /// {@macro providererror}
  ProviderError(this.id);

  /// The id of the provider
  final ProviderId<T> id;

  @override
  String toString() {
    return '''
Error: could not find a ProviderScope containing the given Provider type $T and id $id.
To fix, please:
          
  * Be sure to have a ProviderScope ancestor, the context used must be a descendant.
  * Ensure you provided the right ProviderId<T> to context.get(ProviderId<T> id) 
  * Create providers providing types:
    ```
    ProviderScope(
      providers: [
          nameProviderId.createProvider(
            init: () => const NameProvider('Ale'),
          ),
          counterProviderId.createProvider(
            init: () => Signal(0),
          ),
      ],
    )
    ```
  * The types `NameProvider` and `Signal<int>` are the providers' types. They
  only have to be provided when declaring the Ids.
  E.g. `final nameProviderId = ProviderId<NameProvider>();`.
  
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
/// Error thrown when multiple providers of the same [id] are created together.
/// {@endtemplate}
class ProviderMultipleProviderOfSameTypeError extends Error {
  /// {@macro Providermultipleproviderofsametypeerror}
  ProviderMultipleProviderOfSameTypeError({
    required this.providerType,
    required this.id,
  });

  // ignore: public_member_api_docs
  final Type providerType;

  // ignore: public_member_api_docs
  final ProviderId<dynamic> id;

  @override
  String toString() {
    return '''
      You cannot create or inject multiple providers with the same ProviderId together.
      Provider type: $providerType
      ProviderId: $id
      ''';
  }
}
