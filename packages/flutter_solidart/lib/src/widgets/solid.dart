import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

part '../models/solid_element.dart';

/// {@template solid}
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
/// You're going to see how to build a toggle theme feature using `Solid`, this example is present also [here](https://docs.page/nank1ro/solidart/examples/toggle-theme)
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Provide the theme mode signal to descendats
///     return Solid(
///       providers: [
///         SolidSignal<Signal<ThemeMode>>(
///           create: () => createSignal(ThemeMode.light),
///         ),
///       ],
///       // using the builder method to immediately access the signal
///       builder: (context) {
///         // observe the theme mode value this will rebuild every time the themeMode signal changes.
///         final themeMode = context.observe<ThemeMode>();
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
///             SignalBuilder(
///           signal: themeMode,
///           builder: (_, mode, __) {
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
/// The `SolidSignal` has a `create` function that returns a `SignalBase`.
/// You may create a signal or a derived signal. The value is a Function
/// because the signal is created lazily only when used for the first time, if
/// you never access the signal it never gets created.
/// In the `SolidSignal` you can also specify an identifier for having multiple
/// signals of the same type.
///
/// The `context.observe()` method listen to the signal value and rebuilds the
/// widget when the value changes. It takes an optional `id` that is the signal
/// identifier that you want to use. This method must be called only inside the
/// `build` method.
///
/// The `context.get()` method doesn't listen to the signal value. You may use
/// this method inside the `initState` and `build` methods.
///
/// > It is mandatory to set the type of signal to the `SolidSignal` otherwise
/// you're going to encounter an error, for example:
///
/// ```dart
/// SolidSignal<Signal<ThemeMode>>(create: () => createSignal(ThemeMode.light))
/// ```
/// and `context.observe<ThemeMode>` where ThemeMode is the type of the signal
/// value.
/// `context.get<Signal<ThemeMode>>` where `Signal<ThemeMode>` is the type
/// of signal with its type value.
///
/// ## Providers
///
/// You can also pass `SolidProvider`s to descendants:
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
/// class SolidProvidersPage extends StatelessWidget {
///   const SolidProvidersPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('SolidProviders'),
///       ),
///       body: Solid(
///         providers: [
///           SolidProvider<NameProvider>(
///             create: () => const NameProvider('Ale'),
///             // the dispose method is fired when the [Solid] widget above is removed from the widget tree.
///             dispose: (provider) => provider.dispose(),
///           ),
///           SolidProvider<NumberProvider>(
///             create: () => const NumberProvider(1),
///             // Do not create the provider lazily, but immediately
///             lazy: false,
///             id: 1,
///           ),
///           SolidProvider<NumberProvider>(
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
///       Solid.value(
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
class Solid extends StatefulWidget {
  /// {@macro solid}
  const Solid({
    super.key,
    this.child,
    this.builder,
    this.providers = const [],
  })  : assert(
          (child != null) ^ (builder != null),
          'Provide either a child or a builder',
        ),
        _canAutoDisposeProviders = true;

  /// Private constructor used internally to hide the `autoDispose` field
  const Solid._internal({
    super.key,
    this.providers = const [],
    this.child,
    this.builder,
    required bool autoDispose,
  })  : assert(
          (child != null) ^ (builder != null),
          'Provide either a child or a builder',
        ),
        _canAutoDisposeProviders = autoDispose;

  /// Provide a single or multiple [SolidElement]s to a new route.
  ///
  /// This is useful for passing multiple providers to modals, because are
  /// spawned in a new tree.
  factory Solid.value({
    Key? key,
    SolidElement<dynamic>? element,
    List<SolidElement<dynamic>>? elements,
    required Widget child,
  }) {
    assert(
      (element != null) ^ (elements != null),
      'Provide either a single element or multiple elements',
    );
    return Solid._internal(
      key: key,
      providers: elements ?? [element!],
      autoDispose: false,
      child: child,
    );
  }

  /// The widget child that gets access to the [providers].
  final Widget? child;

  /// The widget builder that gets access to the [providers].
  final WidgetBuilder? builder;

  /// All the providers provided to all the descendants of [Solid].
  final List<SolidElement<dynamic>> providers;

  /// By default signals and providers are going to be auto-disposed when the
  //  Solid widget disposes.
  /// When using Solid.value this is not wanted because the signals and
  // providers are already managed by another Solid widget.
  final bool _canAutoDisposeProviders;

  @override
  State<Solid> createState() => SolidState();

  /// Finds the first SolidState ancestor that satifies the given [id].
  ///
  /// If [listen] is true, the [context] gets subscribed to the given value.
  static SolidState _findState<T>(
    BuildContext context, {
    Identifier? id,
    bool listen = false,
  }) {
    final state = _InheritedSolid.inheritFromNearest<T>(
      context,
      id: id,
      listen: listen,
    )?.state;
    if (state == null) throw SolidProviderError<T>(id);
    return state;
  }

  /// Obtains the Provider of the given type T and [id] corresponding to the
  /// nearest [Solid] widget.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the provider with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the provider is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the provider is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  static T get<T>(BuildContext context, [Identifier? id]) {
    return _getOrCreateProvider<T>(context, id: id);
  }

  /// Tries to obtain the Provider of the given type T and [id] corresponding to
  /// the nearest [Solid] widget.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the provider with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the provider is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the provider is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  static T? maybeGet<T>(BuildContext context, [Identifier? id]) {
    try {
      return _getOrCreateProvider<T>(context, id: id);
    } catch (e) {
      if (e is SolidProviderError<T>) {
        return null;
      }
      rethrow;
    }
  }

  /// Obtains the SolidElement of a Provider of the given type T and [id]
  /// corresponding to the nearest [Solid] widget.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the provider with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the provider is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the provider is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Doesn't listen to the provider so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  static SolidElement<T> getElement<T>(BuildContext context, [Identifier? id]) {
    final state = _findState<T>(context, id: id);
    final element = state.widget.providers.firstWhere((element) {
      return element is SolidElement<T> && element.id == id;
    });
    return element as SolidElement<T>;
  }

  /// Subscribe to the [Signal] of the given value type and [id] corresponding
  /// to the nearest [Solid] widget rebuilding the widget when the value exposed
  /// by the [Signal] changes.
  ///
  /// Throws if no such element or [Solid] widget is found.
  ///
  /// Calling this method is O(N) with a small constant factor where N is the
  /// number of [Solid] ancestors needed to traverse to find the signal with
  /// the given [id].
  ///
  /// If you've a single Solid widget in the whole app N is equal to 1.
  /// If you have two Solid ancestors and the signal is present in the nearest
  /// ancestor, N is still 1.
  /// If you have two Solid ancestors and the signal is present in the farest
  /// ancestor, N is 2, and so on.
  ///
  /// This method should not be called from State.dispose because the element
  /// tree is no longer stable at that time.
  ///
  /// Listens to the signal so it causes the widget to rebuild.
  ///
  /// You must call this method only from the `build` method.
  ///
  /// WARNING: Doesn't support observing a Resource.
  static T observe<T>(BuildContext context, [Identifier? id]) {
    SolidState? state;
    Type? signalType;
    if (id != null) {
      state = _findState<Never>(
        context,
        id: id,
        listen: true,
      );
      signalType = state.widget.providers
          .whereType<SolidSignal<dynamic>>()
          .firstWhere((element) => element.id == id)
          ._valueType;
    } else {
      try {
        state = _findState<Signal<T>>(context, listen: true);
        signalType = Signal<T>;
      } catch (_) {
        try {
          state = _findState<Computed<T>>(context, listen: true);
          signalType = Computed<T>;
        } catch (e) {
          state = _findState<ReadSignal<T>>(context, listen: true);
          signalType = ReadSignal<T>;
        }
      }
    }

    var createdSignal = state._createdProviders.entries
        .firstWhereOrNull(
          (element) =>
              // ignore: avoid_dynamic_calls
              element.value.runtimeType == signalType && element.key.id == id,
        )
        ?.value;

    // if the signal is not already present, create it lazily
    if (createdSignal == null) {
      if (signalType == Signal<T>) {
        createdSignal = state.createProvider<Signal<T>>(id);
      } else if (signalType == ReadSignal<T>) {
        createdSignal = state.createProvider<ReadSignal<T>>(id);
      } else if (signalType == Computed<T>) {
        createdSignal = state.createProvider<Computed<T>>(id);
      }
    }
    return (createdSignal as SignalBase<T>).value;
  }

  /// Convenience method to update a `Signal` value.
  ///
  /// You can use it to update a signal value, e.g:
  /// ```dart
  /// context.update<int>('counter', (value) => value * 2);
  /// ```
  /// This is equal to:
  /// ```dart
  /// // retrieve the signal
  /// final signal = context.get<Signal<int>>('counter');
  /// // update the signal
  /// signal.update((value) => value * 2);
  /// ```
  /// but shorter when you don't need the signal for anything else.
  ///
  /// WARNING: Supports only the `Signal<T>` type
  static void update<T>(
    BuildContext context,
    T Function(T value) callback, [
    Identifier? id,
  ]) {
    // retrieve the signal and update its value
    get<Signal<T>>(context, id).update(callback);
  }

  /// Tries to find a provider of type T from the created providers and returns
  /// it.
  ///
  /// The provider is created in case the find fails.
  static T _getOrCreateProvider<T>(BuildContext context, {Identifier? id}) {
    final state = _findState<T>(context, id: id);
    final createdProvider =
        state._createdProviders.entries.firstWhereOrNull((element) {
      return element.value is T && element.key.id == id;
    })?.value;

    if (createdProvider != null) return createdProvider as T;
    // if the provider is not already present, create it lazily
    return state.createProvider<T>(id);
  }
}

/// The state of the [Solid] widget
class SolidState extends State<Solid> {
  // Stores all the created providers.
  // The key is the provider, while the value is its value.
  final Map<SolidElement<dynamic>, dynamic> _createdProviders = {};

  // Keeps track of the value of each signal, used to detect which signal
  // updated and to implement fine-grained reactivity.
  Map<Identifier, dynamic> _signalValues = {};

  // Stores all the disposeFn for each signal
  final _signalDisposeCallbacks = <DisposeEffect>[];

  @override
  void initState() {
    super.initState();
    // check if the provider type is not dynamic
    // check if there are multiple providers of the same type
    final types = <Type>[];
    for (final provider in widget.providers) {
      final type = provider._valueType;
      if (type == dynamic) throw SolidProviderDynamicError();

      if (types.contains(type) && provider.id == null) {
        throw SolidProviderMultipleProviderOfSameTypeError(
          providerType: type,
        );
      } else {
        types.add(type);
      }
    }
    // create non lazy providers.
    widget.providers
        .whereType<SolidProvider<dynamic>>()
        .where((element) => !element.lazy)
        .forEach((provider) {
      // create and store the provider
      _createdProviders[provider] = provider.create();
    });
  }

  @override
  void dispose() {
    // stop listening to signals and dispose all of them if needed
    for (final disposeFn in _signalDisposeCallbacks) {
      disposeFn();
    }

    // dispose all the created providers
    if (widget._canAutoDisposeProviders) {
      _createdProviders.forEach((provider, value) {
        switch (provider) {
          case SolidProvider():
            provider._disposeFn(context, value);
          case SolidSignal():
            if (provider.autoDispose) {
              (value as SignalBase).dispose();
            }
        }
      });
    }

    _signalDisposeCallbacks.clear();
    _signalValues.clear();
    _createdProviders.clear();
    super.dispose();
  }

  /// -- Signals logic
  void _initializeSignal(SignalBase<dynamic> signal, {required Identifier id}) {
    final unobserve = signal.observe((_, value) {
      _signalValues = Map<Identifier, dynamic>.fromEntries(
        _createdProviders.entries
            .where((element) => element.key is SolidSignal)
            .map(
              (entry) => MapEntry(
                entry.key.id ?? entry.key._valueType,
                entry.key == id ? value : (entry.value as SignalBase).value,
              ),
            ),
      );
      Future.microtask(() {
        if (mounted) setState(() {});
      });
    });
    signal.onDispose(unobserve);

    _signalDisposeCallbacks.add(unobserve);

    // store the initial signal value
    _signalValues[id] = signal.value;
  }

  /// -- Providers logic

  /// Try to find a [SolidProvider] of type <T> or [id] and returns it
  SolidElement<dynamic>? _getProvider<T>(
    Identifier? id,
  ) {
    SolidElement<dynamic>? provider;
    if (id != null) {
      provider = widget.providers.firstWhereOrNull(
        (element) => element.id == id,
      );
    } else {
      provider = widget.providers.firstWhereOrNull(
        (element) {
          return element is SolidElement<T>;
        },
      );
    }
    // search by type next

    if (provider == null) return null;
    return provider;
  }

  /// Creates a provider of type T and stores it
  T createProvider<T>(Identifier? id) {
    // find the provider in the list
    final provider = _getProvider<T>(id)!;
    // create and return it
    final value = provider.create() as T;

    if (provider is SolidSignal && value is SignalBase) {
      _initializeSignal(value, id: id ?? T);
    }

    // store the created provider
    _createdProviders[provider] = value;

    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isProviderInScope<T>(Identifier? id) {
    // Find the provider by type
    return _getProvider<T>(id) != null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSolid(
      state: this,
      signalValues: _signalValues,
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
      IterableProperty(
        'createdProviders',
        _createdProviders.values,
      ),
    );
  }
  // coverage:ignore-end
}

@immutable
class _InheritedSolid extends InheritedModel<Object> {
  const _InheritedSolid({
    // ignore: unused_element
    super.key,
    required this.state,
    required this.signalValues,
    required super.child,
  });

  final SolidState state;
  final Map<Identifier, dynamic> signalValues;

  @override
  bool updateShouldNotify(covariant _InheritedSolid oldWidget) {
    return !const DeepCollectionEquality()
        .equals(oldWidget.signalValues, signalValues);
  }

  bool isSupportedAspectWithType<T>(Identifier? id) {
    return state.isProviderInScope<T>(id);
  }

  /// Fine-grained rebuilding of signals that changed value
  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedSolid oldWidget,
    Set<Object> dependencies,
  ) {
    for (final entry in signalValues.entries) {
      // ignore untracked signals
      if (!dependencies.contains(entry.key)) continue;

      final oldSignalValue = oldWidget.signalValues[entry.key];
      if (entry.value != oldSignalValue) {
        return true;
      }
    }
    return false;
  }

  // The following two methods are taken from [InheritedModel] and modified
  // in order to find the first [_InheritedSolid] ancestor that contains the
  // searched Signal id [aspect] or provider of type [ProviderType].
  // This is a small opmitization that avoids traversing all the [Solid]
  // ancestors.
  // The [result] will be a single _InheritedSolid of context's type T ancestor
  // that supports the specified model [aspect].
  static InheritedElement? _findNearestModel<T>(
    BuildContext context, {
    Identifier? id,
  }) {
    final model =
        context.getElementForInheritedWidgetOfExactType<_InheritedSolid>();
    // No ancestors of type T found, exit.
    if (model == null) {
      return null;
    }

    assert(
      model.widget is _InheritedSolid,
      'The widget must be of type _InheritedSolid',
    );
    final modelWidget = model.widget as _InheritedSolid;

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

    return _findNearestModel<T>(
      modelParent!,
      id: id,
    );
  }

  /// Makes [context] dependent on the specified [id] of an
  /// [_InheritedSolid]
  ///
  /// When the given [id] of the model changes, the [context] will be
  /// rebuilt if [listen] is set to true.
  ///
  /// The dependencies created by this method target the nearest
  /// [_InheritedSolid] ancestor which [isSupportedAspect]  returns true.
  ///
  /// If [id] is null this method is the same as
  /// `context.dependOnInheritedWidgetOfExactType<T>()` if [listen] is true,
  /// otherwise it's a simple
  /// `context.getElementForInheritedWidgetOfExactType<T>()`.
  ///
  /// If no ancestor of type T exists, null is returned.
  static _InheritedSolid? inheritFromNearest<T>(
    BuildContext context, {
    Identifier? id,
    // Whether to listen to the [InheritedModel], defaults to false.
    bool listen = false,
  }) {
    // Try finding a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel<T>(
      context,
      id: id,
    );
    if (model == null) {
      return null;
    }

    // depend on the inherited element if [listen] is true
    if (listen) {
      context.dependOnInheritedElement(model, aspect: id ?? T)
          as _InheritedSolid;
    }

    return model.widget as _InheritedSolid;
  }
}

/// {@template solidprovidererror}
/// Error thrown when the [SolidProvider] of type [id] cannot be found
/// {$endtemplate}
class SolidProviderError<T> extends Error {
  /// {@macro solidprovidererror}
  SolidProviderError(this.id);

  /// The id of the provider
  final Identifier? id;

  @override
  String toString() {
    return '''
Error could not fint a Solid containing the given SolidProvider type $T and id $id
To fix, please:
          
  * Be sure to have a Solid ancestor, the context used must be a descendant.
  * Provide types to context.get<ProviderType>() 
  * Create providers providing types: 
    ```
    Solid(
      providers: [
          SolidProvider<NameProvider>(
            create: () => const NameProvider('Ale'),
          ),
          SolidSignal<Signal<int>>(
            create: () => createSignal(0),
          ),
      ],
    )
    ```
  * The type `NameProvider` and `Signal<int>` are the provider's types.
  
If none of these solutions work, please file a bug at:
https://github.com/nank1ro/solidart/issues/new
      ''';
  }
}

/// Error thrown when the [SolidProvider] has a `dynamic` Type.
class SolidProviderDynamicError extends Error {
  @override
  String toString() {
    return '''
    Seems like that you forgot to declare the provider type.
    You have `SolidProvider()` but it should be `SolidProvider<ProviderType>()`.
      ''';
  }
}

/// {@template solidprovidermultipleproviderofsametypeerror}
/// Error thrown when there are multiple providers of the same [providerType]
/// Type in the same [Solid] widget
/// {$endtemplate}
class SolidProviderMultipleProviderOfSameTypeError extends Error {
  /// {@macro solidprovidermultipleproviderofsametypeerror}
  SolidProviderMultipleProviderOfSameTypeError({required this.providerType});

  /// The type of the provider
  final Type providerType;
  @override
  String toString() {
    return '''
      You cannot have multiple providers of the same type without specifing a different `id`entifier to each one.
      Seems like you declared the type $providerType multiple times in the list of providers.
      ''';
  }
}
