// ignore_for_file: public_member_api_docs

import 'package:meta/meta.dart';
import 'package:solidart/src/core/derivation.dart';
import 'package:solidart/src/core/reactive_context.dart';

/// {@template atom}
/// Creates a simple Atom for tracking its usage in a reactive context. This is
/// useful when you don't need the value but instead a way of knowing when it
//// becomes active and inactive in a reaction.
/// {@endtemplate}
@internal
class Atom {
  /// {@macro atom}
  Atom({
    String? name,
  }) : name = name ?? ReactiveContext.main.nameFor('Atom');

  @internal
  final ReactiveContext context = ReactiveContext.main;

  final String name;

  @internal
  bool isPendingUnobservation = false;

  @internal
  DerivationState lowestObserverState = DerivationState.notTracking;

  bool isBeingObserved = false;

  @internal
  final Set<Derivation> observers = {};

  bool get hasObservers => observers.isNotEmpty;

  @internal
  void reportObserved() {
    context.reportObserved(this);
  }

  @internal
  void reportChanged() {
    context
      ..startBatch()
      ..propagateChanged(this)
      ..endBatch();
  }

  @internal
  void addObserver(Derivation d) {
    observers.add(d);

    if (lowestObserverState.index > d.dependenciesState.index) {
      lowestObserverState = d.dependenciesState;
    }
  }

  @internal
  void removeObserver(Derivation d) {
    observers.remove(d);
    if (observers.isEmpty) {
      context.enqueueForUnobservation(this);
    }
  }
}
