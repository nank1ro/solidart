import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// The id of a signal
typedef SignalIdentifier = Object;

/// A map of signals with their ids.
typedef SignalsMapper = Map<SignalIdentifier, SignalBase<dynamic> Function()>;

/// Used internally to avoid searching for a provider
class _NoProvider {}

/// Provides [signals] and [providers] to descendants.

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
/// /// The identifiers used for [Solid] signals.
/// ///
/// /// We've used an _Enum_ to store all the [SignalId]s.
/// /// You may use a `String`, an `int` or wethever you want.
/// /// Just be sure to use the same id to retrieve the signal.
/// enum SignalId {
///   themeMode,
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Provide the `themeMode` signal to descendants
///     return Solid(
///       signals: {
///           // the id of the signal and the signal associated.
///         SignalId.themeMode: () => createSignal<ThemeMode>(ThemeMode.light),
///       },
///       child:
///           // using a builder here because the `context` must be a descendant of [Solid]
///           Builder(
///         builder: (context) {
///           // observe the `themeMode` value this will rebuild every time the themeMode signal changes.
///           // we `observe` the value of a signal.
///           final themeMode = context.observe<ThemeMode>(SignalId.themeMode);
///           return MaterialApp(
///             title: 'Toggle theme',
///             themeMode: themeMode,
///             theme: ThemeData.light(),
///             darkTheme: ThemeData.dark(),
///             home: const MyHomePage(),
///           );
///         },
///       ),
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
///     final themeMode = context.get<Signal<ThemeMode>>(SignalId.themeMode); // [4]
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
/// The `Solid` widgets takes a Map of `signals`:
///
/// - The key of the Map is the signal id, in this case `SignalId.themeMode`.
/// - The value of the Map is a function that returns a `SignalBase`. You may
/// create a signal or a derived signal. The value is a Function because the
/// signal is created lazily only when used for the first time, if you never
/// access the signal it never gets created.
///
/// The `context.observe()` method listen to the signal value and rebuilds the
/// widget when the value changes. It takes an `id` that is the signal
/// identifier that you want to use. This method must be called only inside
/// the `build` method.
///
/// The `context.get()` method doesn't listen to the signal value. You may use
/// this method inside the `initState` and `build` methods.
///
/// > It is mandatory to pass the type of signal value otherwise you're going
/// to encounter an error, for example:
///
/// 1. `createSignal<ThemeMode>` and `context.observe<ThemeMode>` where
/// ThemeMode is the type of the signal value.
/// 2. `context.get<Signal<ThemeMode>>` where `Signal<ThemeMode>` is the type
/// of signal with its type value.
///
/// ## Solid.value
///
/// The `Solid.value` factory is useful for passing `signals` to modals.
/// This is necessary because modals are spawned in a new tree.
/// `Solid.value` takes just:
/// - `context` a BuildContext that has access to signals
/// - `signalIds` a list of signal identifiers that you want to provide to the
/// modal
///
/// Here it is a chuck of code taken from [this example](/examples/general).
///
/// ```dart
/// Future<void> showCounterDialog(BuildContext context) {
///   return showDialog(
///     context: context,
///     builder: (dialogContext) {
///       // using `Solid.value` we provide the existing signal(s) to the dialog
///       return Solid.value(
///         // the context passed must have access to the Solid signals
///         context: context,
///         // the signals ids that we want to provide to the modal
///         signalIds: const [_SignalId.counter, _SignalId.doubleCounter],
///         child: Builder(
///           builder: (innerContext) {
///             final counter = innerContext.observe<int>(_SignalId.counter);
///             final doubleCounter =
///                 innerContext.observe<int>(_SignalId.doubleCounter);
///             return Dialog(
///               child: SizedBox(
///                 width: 200,
///                 height: 100,
///                 child: Center(
///                   child: ListTile(
///                     title: Text("The counter is $counter"),
///                     subtitle: Text('The doubleCounter is $doubleCounter'),
///                   ),
///                 ),
///               ),
///             );
///           },
///         ),
///       );
///     },
///   );
/// }
/// ```
@immutable
class Solid extends StatefulWidget {
  /// Default constructor
  const Solid({
    super.key,
    required this.child,
    this.signals = const {},
    this.providers = const [],
  }) : _autoDispose = true;

  /// Private constructor used internally to hide the `autoDispose` field
  const Solid._internal({
    super.key,
    this.signals = const {},
    this.providers = const [],
    required this.child,
    required bool autoDispose,
  }) : _autoDispose = autoDispose;

  /// Takes a list of [signalIds], a [context] that must have access to the
  /// signals and a [child] which will have access to the signals
  ///
  /// This is useful for passing signals to modals, because are spawned in a
  /// new tree.
  factory Solid.value({
    Key? key,
    required BuildContext context,
    required Widget child,
    List<SignalIdentifier> signalIds = const [],
    List<Type> providerTypes = const [],
  }) {
    // retrieve the signals
    final signals = <SignalIdentifier, SignalBase<dynamic> Function()>{};
    for (final id in signalIds) {
      final stateContainingSignal =
          _findState<_NoProvider>(context, aspect: id);
      signals[id] = stateContainingSignal.widget.signals[id]!;
    }

    for (final type in providerTypes) {
      final state = _findState(context, aspect: type);
      print("state: $state");
    }
    /*
     TODO(alex): If I get a list of provider [Type]s I lose its type when
      wrapping each one on a new list.
      Refactor to support multiple providers here if there is a way to do it.
      This could have been done transforming the list of providers into a Map
      of Providers with an identifier, like for signals. But seems overkill.
      With the ID this issue will no longer be present and the user could
      create many providers of the same type in the same scope and the
      `Solid.providerValue` constructor could be deleted because useless.
      But this doesn't seem a common scenario and forcing the user to provide
      an ID for each provider seems a very bad idea.
    */
    return Solid._internal(
      key: key,
      signals: signals,
      autoDispose: false,
      child: child,
    );
  }

  /// Provides a provider value to a new tree.
  ///
  /// It takes a provider [value] and a [child] that will get access to the
  /// provider.
  /// This is useful for passing providers to modals, because are spawned in a
  /// new tree.
  // factory Solid.providerValue({
  //   Key? key,
  //   required P value,
  //   required Widget child,
  // }) {
  //   return Solid._internal(
  //     key: key,
  //     autoDispose: false,
  //     providers: [SolidProvider<P>(create: (_) => value)],
  //     child: child,
  //   );
  // }
  //
  final Widget child;

  /// All the signals provided to all the descendants of [Solid].
  ///
  /// The key is the signal identifier.
  /// The function must return a signal.
  /// The value is a function in order to create signals lazily only when needed
  final SignalsMapper signals;

  /// All the providers provided to all the descendants of [Solid].
  final List<SolidProvider<dynamic>> providers;

  /// By default signals and providers are going to be auto-disposed when the
  //  Solid widget disposes.
  /// When using Solid.value this is not wanted because the signals and
  // providers are already managed by another Solid widget.
  final bool _autoDispose;

  @override
  State<Solid> createState() => SolidState();

  static SolidState _findState<ProviderType>(
    BuildContext context, {
    Object? aspect,
    bool listen = false,
  }) {
    final state = _InheritedSolid.inheritFromNearest<ProviderType>(
      context,
      aspect: aspect,
      listen: listen,
    )?.state;
    if (state == null) {
      throw SolidError(signalId: aspect, providerType: ProviderType);
    }
    return state;
  }

  // Checks that the signal type correspondes to the given type provided.
  // If you created a [Signal] you cannot get it as a [ReadableSignal], and
  // vice versa.
  // This operation is performed only in development mode.
  static void _checkSignalType<S>({
    required SolidState state,
    required SignalIdentifier id,
  }) {
    assert(
      () {
        Type typeOf<X>() => X;
        final t = typeOf<S>();
        final isTypeReadable = t.toString().startsWith('ReadableSignal');
        final isSignalReadable = state.isReadableSignal(id: id);

        // ignore: avoid_positional_boolean_parameters
        String typeString(bool isReadable) {
          return isReadable ? 'ReadableSignal' : 'Signal';
        }

        if (isTypeReadable != isSignalReadable) {
          throw Exception('''
You trying to access a ${typeString(isSignalReadable)} as a ${typeString(isTypeReadable)}
The signal id that caused this issue is $id
''');
        }
        return true;
      }(),
      '',
    );
  }

  /// Obtains the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget.
  static S _getOrCreateSignal<S extends SignalBase<dynamic>>(
    BuildContext context,
    SignalIdentifier id, {
    bool listen = false,
    // An optional state, provided only by Solid.value to avoid repeating the
    // _findState method.
    SolidState? currentState,
  }) {
    final state = currentState ??
        _findState<_NoProvider>(context, aspect: id, listen: listen);
    _checkSignalType<S>(state: state, id: id);

    final createdSignal = state._createdSignals[id] as S?;
    // if the signal is not already present, create it lazily
    return createdSignal ?? state.createSignal<S>(id: id);
  }

  /// Obtains the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget.
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
  /// Doesn't listen to the signal so it won't cause the widget to rebuild.
  ///
  /// You may call this method inside the `initState` or `build` methods.
  static S get<S extends SignalBase<dynamic>>(
    BuildContext context,
    SignalIdentifier id,
  ) {
    return _getOrCreateSignal<S>(context, id);
  }

  /// Subscribe to the [Signal] of the given type and [id] corresponding to the
  /// nearest [Solid] widget rebuilding the widget when the value exposed by the
  /// [Signal] changes.
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
  static T observe<T>(
    BuildContext context,
    SignalIdentifier id,
  ) {
    final state = _findState<_NoProvider>(context, aspect: id, listen: true);

    // retrieve the signal
    var createdSignal = state._createdSignals[id];

    // if the signal is not already present, create it lazily
    if (createdSignal == null) {
      if (state.isReadableSignal(id: id)) {
        createdSignal = state.createSignal<ReadableSignal<T>>(id: id);
      } else {
        createdSignal = state.createSignal<Signal<T>>(id: id);
      }
    }
    // return the signal value
    return createdSignal.value as T;
  }

  /// Providers logic
  static P getProvider<P>(
    BuildContext context,
  ) {
    return _getOrCreateProvider<P>(context);
  }

  static P _getOrCreateProvider<P>(
    BuildContext context, {
    bool listen = false,
    // An optional state, provided only by Solid.value to avoid repeating the
    // _findState method.
    SolidState? currentState,
  }) {
    final state = currentState ?? _findState<P>(context, listen: listen);

    final createdProvider = state._createdProviders.values
        .firstWhereOrNull((element) => element is P);
    if (createdProvider != null) return createdProvider as P;
    // if the provider is not already present, create it lazily
    return state.createProvider<P>();
  }
}

class SolidState extends State<Solid> {
  // Stores all the created signals.
  final Map<SignalIdentifier, SignalBase<dynamic>> _createdSignals = {};

  // Stores all the created providers.
  // The key is the provider, while the value is its value.
  final Map<SolidProvider<dynamic>, dynamic> _createdProviders = {};

  // Keeps track of the value of each signals, used to detect which signal
  // updated and to implement fine-grained reactivity.
  Map<SignalIdentifier, dynamic> _signalValues = {};

  @override
  void initState() {
    super.initState();
    // create non lazy providers.
    //widget.providers.where((element) => !element.lazy).forEach((provider) {
    // create and store the provider
    //   _createdProviders[provider] = provider.create(context);
    // });
  }

  @override
  void dispose() {
    // dispose all the created signals
    for (final signal in _createdSignals.values) {
      _stopListeningToSignal(signal);
      if (widget._autoDispose) signal.dispose();
    }
    // dispose all the created providers
    print(_createdProviders);
    if (widget._autoDispose) {
      _createdProviders.forEach((provider, value) {
        // provider.dispose?.call(value);
        print(provider.dispose);
      });
    }

    _createdSignals.clear();
    _signalValues.clear();
    _createdProviders.clear();
    super.dispose();
  }

  /// Signals logic

  // Indicates is the signal is readable.
  bool isReadableSignal({required SignalIdentifier id}) {
    return widget.signals[id] is! Signal<dynamic> Function();
  }

  /// Creates a signal with a value of type T:
  S createSignal<S>({required SignalIdentifier id}) {
    final signal = widget.signals[id]!();
    // store the created signal
    _createdSignals[id] = signal;

    _initializeSignal(signal, id: id);

    return signal as S;
  }

  void _initializeSignal(
    SignalBase<dynamic> signal, {
    required SignalIdentifier id,
  }) {
    _listenToSignal(signal);
    signal.onDispose(() {
      _stopListeningToSignal(signal);
    });

    // store the initial signal value
    _signalValues[id] = signal.value;
  }

  /// Used to determine if the requested signal for the given
  /// [id]entifier is present in the current scope
  bool isSignalInScope(SignalIdentifier id) {
    return widget.signals.containsKey(id);
  }

  void _listenToSignal(SignalBase<dynamic> signal) {
    signal.addListener(_onSignalChange);
  }

  void _stopListeningToSignal(SignalBase<dynamic> signal) {
    signal.removeListener(_onSignalChange);
  }

  void _onSignalChange() {
    setState(() {
      // update the map that keeps track of each signal value
      _signalValues = Map<SignalIdentifier, dynamic>.fromEntries(
        _createdSignals.entries.map(
          (entry) => MapEntry(entry.key, entry.value.value),
        ),
      );
    });
  }

  /// Providers logic
  SolidProvider<P>? _getProviderOfType<P>() {
    final provider = widget.providers.firstWhereOrNull(
      (element) => element.create is P Function(BuildContext),
    );
    if (provider == null) return null;
    return provider as SolidProvider<P>;
  }

  P createProvider<P>() {
    // find the provider in the list
    final provider = _getProviderOfType<P>()!;
    // create and return it
    final value = provider.create(context);

    // store the created provider
    _createdProviders[provider] = value;

    return value;
  }

  /// Used to determine if the requested provider is present in the current
  /// scope
  bool isProviderInScope<P>() {
    // Find the provider by type P
    return _getProviderOfType<P>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedSolid(
      state: this,
      signalValues: _signalValues,
      child: widget.child,
    );
  }

  // coverage:ignore-start
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty(
          'createdSignals',
          _createdSignals.values,
        ),
      )
      ..add(
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
  final Map<SignalIdentifier, dynamic> signalValues;

  @override
  bool updateShouldNotify(covariant _InheritedSolid oldWidget) {
    return !const DeepCollectionEquality()
        .equals(oldWidget.signalValues, signalValues);
  }

  // Used to determine in which ancestor is the given [aspect].
  @override
  bool isSupportedAspect(Object aspect) {
    return state.isSignalInScope(aspect);
  }

  // Used to determine in which ancestor is the given provider type P.
  bool isProviderInScope<P>() {
    return state.isProviderInScope<P>();
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
  static InheritedElement? _findNearestModel<ProviderType>(
    BuildContext context, {
    Object? aspect,
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
    if (aspect != null && modelWidget.isSupportedAspect(aspect)) {
      return model;
    }

    // The model contains the provider, the ancestor has been found, return it.
    if (aspect == null &&
        ProviderType is! _NoProvider &&
        modelWidget.isProviderInScope<ProviderType>()) {
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

    return _findNearestModel<ProviderType>(modelParent!, aspect: aspect);
  }

  /// Makes [context] dependent on the specified [aspect] or provider with type
  /// [ProviderType] of an [_InheritedSolid]
  ///
  /// When the given [aspect] of the model changes, the [context] will be
  /// rebuilt if [listen] is set to true.
  ///
  /// The dependencies created by this method target the nearest
  /// [_InheritedSolid] ancestorfor which [isSupportedAspect] or
  /// [isProviderInScope] returns true.
  ///
  /// If [aspect] is null this method is the same as
  /// `context.dependOnInheritedWidgetOfExactType<T>()` if [listen] is true,
  /// otherwise it's a simple
  /// `context.getElementForInheritedWidgetOfExactType<T>()`.
  ///
  /// If no ancestor of type T exists, null is returned.
  static _InheritedSolid? inheritFromNearest<ProviderType>(
    BuildContext context, {
    SignalIdentifier? aspect,
    // Whether to listen to the [InheritedModel], defaults to false.
    bool listen = false,
  }) {
    // Try finding a model in the ancestors for which isSupportedAspect(aspect)
    // is true.
    final model = _findNearestModel<ProviderType>(context, aspect: aspect);
    if (model == null) {
      return null;
    }

    // depend on the inherited element if [listen] is true
    if (listen) {
      context.dependOnInheritedElement(model, aspect: aspect!)
          as _InheritedSolid;
    }

    return model.widget as _InheritedSolid;
  }
}

class SolidError extends Error {
  SolidError({
    this.signalId,
    this.providerType,
  });

  final SignalIdentifier? signalId;
  final Type? providerType;

  @override
  String toString() {
    if (providerType != null) {
      return '''Error could not fint a Solid containing the given SolidProvider type $providerType''';
    }
    return '''
Error: Could not find a Solid containing the given Signal with id $signalId.
    
To fix, please:
          
  * Be sure to have a Solid ancestor, the context used must be below.
  * Provide types to context.get<SignalType>('some-id') 
  * Create signals providing types: 
    ```
    Solid(
      signals: {
        'counter': () => createSignal<int>(0),
      },
    )
    ```
  * The type and id you use to create and consume a signal must match.
  
If none of these solutions work, please file a bug at:
https://github.com/nank1ro/solidart/issues/new
      ''';
  }
}
