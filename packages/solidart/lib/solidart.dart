/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

// `ReactiveSystem`/`reactiveSystem`/`MayDisposeDependencies` are the reactive
// adapter: they expose internal alien_signals types (ReactiveNode/Link) and are
// not public API. Sibling packages reach them via
// `package:solidart/solidart_internal.dart`.
export 'src/core/core.dart'
    hide
        MayDisposeDependencies,
        ReactionErrorHandler,
        ReactionInterface,
        ReactiveName,
        ReactiveSystem,
        ValueComparator,
        reactiveSystem;
export 'src/extensions/until.dart';
export 'src/utils.dart'
    show
        DebounceOperation,
        Debouncer,
        SolidartCaughtException,
        SolidartException,
        SolidartReactionException;
