// ignore_for_file: public_member_api_docs
part of 'core.dart';

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

  final ReactiveContext _context = ReactiveContext.main;

  final String name;

  // ignore this lint, is a false statement, because the values is changed by
  // reactive context.
  // ignore: prefer_final_fields
  bool _isPendingUnobservation = false;
  DerivationState _lowestObserverState = DerivationState.notTracking;

  bool isBeingObserved = false;

  final Set<Derivation> _observers = {};

  bool get hasObservers => _observers.isNotEmpty;

  void _reportObserved() {
    _context.reportObserved(this);
  }

  void _reportChanged() {
    _context
      ..startBatch()
      ..propagateChanged(this)
      ..endBatch();
  }

  void _addObserver(Derivation d) {
    _observers.add(d);

    if (_lowestObserverState.index > d._dependenciesState.index) {
      _lowestObserverState = d._dependenciesState;
    }
  }

  void _removeObserver(Derivation d) {
    _observers.remove(d);
    if (_observers.isEmpty) {
      _context.enqueueForUnobservation(this);
    }
  }
}
