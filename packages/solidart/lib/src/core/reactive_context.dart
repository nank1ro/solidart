// ignore_for_file: public_member_api_docs

import 'package:meta/meta.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/core/computed.dart';
import 'package:solidart/src/core/derivation.dart';
import 'package:solidart/src/core/effect.dart';
import 'package:solidart/src/utils.dart';

class _ReactiveState {
  /// Current batch depth. This is used to track the depth of `transaction` / `action`.
  /// When the batch ends, we execute all the [pendingReactions]
  int batch = 0;

  /// Monotonically increasing counter for assigning a name to an action/reaction/atom
  int nextIdCounter = 0;

  /// Tracks the currently executing derivation (reactions or computeds).
  /// The Observables used here are linked to this derivation.
  Derivation? trackingDerivation;

  /// The reactions that must be triggered at the end of a `transaction` or an
  /// `action`
  List<ReactionInterface> pendingReactions = [];

  /// Are we in middle of executing the [pendingReactions].
  bool isRunningReactions = false;

  /// The atoms that must be disconnected from their observed reactions. This
  /// happens if a reaction has been disposed during a batch
  List<Atom> pendingUnobservations = [];

  /// Tracks if within a computed property evaluation
  int computationDepth = 0;

  /// Tracks if observables can be mutated
  bool allowStateChanges = true;

  /// Are we inside an action or transaction?
  bool get isWithinBatch => batch > 0;
}

typedef ReactionErrorHandler = void Function(
  Object error,
  ReactionInterface reaction,
);

/// Configuration used by [ReactiveContext]
@internal
class ReactiveConfig {
  ReactiveConfig({
    this.maxIterations = 100,
  });

  /// The main or default configuration used by [ReactiveContext]
  static final ReactiveConfig main = ReactiveConfig();

  /// Max number of iterations before bailing out for a cyclic reaction
  final int maxIterations;
}

class ReactiveContext {
  ReactiveContext._main();

  /// The main reactive context
  static final ReactiveContext main = ReactiveContext._main();
  final config = ReactiveConfig.main;

  _ReactiveState _state = _ReactiveState();

  int get nextId => ++_state.nextIdCounter;

  String nameFor(String prefix) {
    assert(prefix.isNotEmpty, 'the prefix cannot be empty');
    return '$prefix@$nextId';
  }

  bool get isWithinBatch => _state.isWithinBatch;

  void startBatch() {
    _state.batch++;
  }

  void endBatch() {
    if (--_state.batch == 0) {
      runReactions();

      for (var i = 0; i < _state.pendingUnobservations.length; i++) {
        final ob = _state.pendingUnobservations[i]
          ..isPendingUnobservation = false;

        if (ob.observers.isEmpty) {
          if (ob.isBeingObserved) {
            // if this observable had reactive observers, trigger the hooks
            ob.isBeingObserved = false;
          }

          if (ob is Computed) {
            ob.suspend();
          }
        }
      }

      _state.pendingUnobservations = [];
    }
  }

  Derivation? startTracking(Derivation derivation) {
    final prevDerivation = _state.trackingDerivation;
    _state.trackingDerivation = derivation;

    _resetDerivationState(derivation);
    derivation.newObservables = {};

    return prevDerivation;
  }

  void endTracking(Derivation currentDerivation, Derivation? prevDerivation) {
    _state.trackingDerivation = prevDerivation;
    _bindDependencies(currentDerivation);
  }

  T? trackDerivation<T>(Derivation d, T Function() fn) {
    final prevDerivation = startTracking(d);
    T? result;

    try {
      result = fn();
      d.errorValue = null;
    } on Object catch (e, s) {
      d.errorValue = SolidartCaughtException(e, stackTrace: s);
    }

    endTracking(d, prevDerivation);
    return result;
  }

  void reportObserved(Atom atom) {
    final derivation = _state.trackingDerivation;

    if (derivation != null) {
      derivation.newObservables!.add(atom);
      if (!atom.isBeingObserved) {
        atom.isBeingObserved = true;
      }
    }
  }

  void _bindDependencies(Derivation derivation) {
    final staleObservables =
        derivation.observables.difference(derivation.newObservables!);
    final newObservables =
        derivation.newObservables!.difference(derivation.observables);
    var lowestNewDerivationState = DerivationState.upToDate;

    // Add newly found observables
    for (final observable in newObservables) {
      observable.addObserver(derivation);

      // Computed = Observable + Derivation
      if (observable is Computed) {
        if (observable.dependenciesState.index >
            lowestNewDerivationState.index) {
          lowestNewDerivationState = observable.dependenciesState;
        }
      }
    }

    // Remove previous observables
    for (final ob in staleObservables) {
      ob.removeObserver(derivation);
    }

    if (lowestNewDerivationState != DerivationState.upToDate) {
      derivation
        ..dependenciesState = lowestNewDerivationState
        ..onBecomeStale();
    }

    derivation
      ..observables = derivation.newObservables!
      ..newObservables = {}; // No need for newObservables beyond this point
  }

  void addPendingReaction(ReactionInterface reaction) {
    _state.pendingReactions.add(reaction);
  }

  void runReactions() {
    if (_state.batch > 0 || _state.isRunningReactions) {
      return;
    }

    _runReactionsInternal();
  }

  void _runReactionsInternal() {
    _state.isRunningReactions = true;

    var iterations = 0;
    final allReactions = _state.pendingReactions;

    // While running reactions, new reactions might be triggered.
    // Hence we work with two variables and check whether
    // we converge to no remaining reactions after a while.
    while (allReactions.isNotEmpty) {
      if (++iterations == config.maxIterations) {
        final failingReaction = allReactions[0];

        // Resetting ensures we have no bad-state left
        _resetState();

        throw SolidartReactionException('''
Reaction doesn't converge to a stable state after ${config.maxIterations} iterations.
Probably there is a cycle in the reactive function: $failingReaction ''');
      }

      final remainingReactions = allReactions.toList(growable: false);
      allReactions.clear();
      for (final reaction in remainingReactions) {
        reaction.run();
      }
    }

    _state
      ..pendingReactions = []
      ..isRunningReactions = false;
  }

  void propagateChanged(Atom atom) {
    if (atom.lowestObserverState == DerivationState.stale) {
      return;
    }

    atom.lowestObserverState = DerivationState.stale;

    for (final observer in atom.observers) {
      if (observer.dependenciesState == DerivationState.upToDate) {
        observer.onBecomeStale();
      }
      observer.dependenciesState = DerivationState.stale;
    }
  }

  void propagatePossiblyChanged(Atom atom) {
    if (atom.lowestObserverState != DerivationState.upToDate) {
      return;
    }

    atom.lowestObserverState = DerivationState.possiblyStale;

    for (final observer in atom.observers) {
      if (observer.dependenciesState == DerivationState.upToDate) {
        observer
          ..dependenciesState = DerivationState.possiblyStale
          ..onBecomeStale();
      }
    }
  }

  void propagateChangeConfirmed(Atom atom) {
    if (atom.lowestObserverState == DerivationState.stale) {
      return;
    }

    atom.lowestObserverState = DerivationState.stale;

    for (final observer in atom.observers) {
      if (observer.dependenciesState == DerivationState.possiblyStale) {
        observer.dependenciesState = DerivationState.stale;
      } else if (observer.dependenciesState == DerivationState.upToDate) {
        atom.lowestObserverState = DerivationState.upToDate;
      }
    }
  }

  void clearObservables(Derivation derivation) {
    final observables = derivation.observables;
    derivation.observables = {};

    for (final x in observables) {
      x.removeObserver(derivation);
    }

    derivation.dependenciesState = DerivationState.notTracking;
  }

  void enqueueForUnobservation(Atom atom) {
    if (atom.isPendingUnobservation) {
      return;
    }

    atom.isPendingUnobservation = true;
    _state.pendingUnobservations.add(atom);
  }

  void _resetDerivationState(Derivation d) {
    if (d.dependenciesState == DerivationState.upToDate) {
      return;
    }

    d.dependenciesState = DerivationState.upToDate;
    for (final obs in d.observables) {
      obs.lowestObserverState = DerivationState.upToDate;
    }
  }

  bool shouldCompute(Derivation derivation) {
    switch (derivation.dependenciesState) {
      case DerivationState.upToDate:
        return false;

      case DerivationState.notTracking:
      case DerivationState.stale:
        return true;

      case DerivationState.possiblyStale:
        return untracked(() {
          for (final obs in derivation.observables) {
            if (obs is Computed) {
              // Force a computation
              try {
                obs.value;
              } on Object catch (_) {
                return true;
              }

              if (derivation.dependenciesState == DerivationState.stale) {
                return true;
              }
            }
          }

          _resetDerivationState(derivation);
          return false;
        });
    }
  }

  bool hasCaughtException(Derivation d) =>
      d.errorValue is SolidartCaughtException;

  Derivation? startUntracked() {
    final prevDerivation = _state.trackingDerivation;
    _state.trackingDerivation = null;
    return prevDerivation;
  }

  // ignore: use_setters_to_change_properties
  void endUntracked(Derivation? prevDerivation) {
    _state.trackingDerivation = prevDerivation;
  }

  T untracked<T>(T Function() fn) {
    final prevDerivation = startUntracked();
    try {
      return fn();
    } finally {
      endUntracked(prevDerivation);
    }
  }

  void pushComputation() {
    _state.computationDepth++;
  }

  void popComputation() {
    _state.computationDepth--;
  }

  void _resetState() {
    _state = _ReactiveState()..allowStateChanges = true;
  }
}
