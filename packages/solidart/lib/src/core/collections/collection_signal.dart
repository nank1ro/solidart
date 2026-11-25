part of '../core.dart';

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
///
/// A collection changed when its length changed, or when an object of
/// [_identitiesOf] is not `identical` to the object at the same position
/// before.
mixin _CollectionSignal<C> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// The objects of [collection] that [_mutate] compares with `identical`,
  /// in iteration order.
  Iterable<Object?> _identitiesOf(C collection);

  /// Saves the previous value of [collection] before a mutation.
  ///
  /// [identities] came from [_identitiesOf] on [collection]. Returns a
  /// function that gives the previous value. [_mutate] calls it only after
  /// a change.
  C Function() _savePrevious(C collection, List<Object?> identities);

  /// The collection that the outermost running [_mutate] copied.
  C? _mutating;

  @override
  C setValue(C newValue) {
    final old = _untrackedValue;
    if (_compare(old, newValue)) {
      return newValue;
    }
    if (trackPreviousValue) {
      // An outer [_mutate] may still change the outgoing collection.
      _setPreviousValue(
        identical(old, _mutating)
            ? _savePrevious(old, _identitiesOf(old).toList())()
            : old,
      );
    }
    // Like `Signal.setValue`: assigning `_value` notifies subscribers once.
    _value = newValue;
    _notifySignalUpdate();
    return newValue;
  }

  /// Runs [mutation] on the collection that holds the value.
  ///
  /// If the collection changed, even when [mutation] throws, records the
  /// collection as it was before as the previous value and notifies once.
  /// A [_mutate] inside [mutation] on the same collection does not notify:
  /// this one notifies once for both. If [mutation] assigns a new
  /// collection, the assignment notifies, so this one does not.
  ///
  /// Set [resizes] when [mutation] runs no code of the caller and changes
  /// the collection only when it changes its length. Then, without history,
  /// the length tells whether the collection changed, so the collection is
  /// not copied.
  ///
  /// The error of [mutation] wins over an error of the notification, which
  /// goes to the current [Zone].
  R _mutate<R>(R Function(C collection) mutation, {bool resizes = false}) {
    final collection = _untrackedValue;
    if (identical(collection, _mutating)) return mutation(collection);
    final outer = _mutating;
    final length = _lengthOf(collection);
    final before = resizes && !trackPreviousValue
        ? null
        : _identitiesOf(collection).toList();
    final previous = trackPreviousValue
        ? _savePrevious(collection, before!)
        : null;
    late final R result;
    _mutating = collection;
    final errors = _FirstError()..run(() => result = mutation(collection));
    _mutating = outer;
    var changed = false;
    errors.run(() {
      if (!identical(_untrackedValue, collection)) return;
      changed = length != _lengthOf(collection);
      if (before != null && !changed) {
        var i = 0;
        changed = _identitiesOf(
          collection,
        ).any((object) => !identical(object, before[i++]));
      }
    });
    if (changed) {
      // The change is done, so it notifies even if [previous] throws.
      if (previous != null) errors.run(() => _setPreviousValue(previous()));
      errors.run(_notifyChanged);
    }
    errors.rethrowIfAny();
    return result;
  }

  /// Runs [mutation] like [_mutate], or directly on the collection when
  /// [unchanged] is true, so the collection is not copied or compared. The
  /// collection still runs [mutation], so it throws like a plain collection.
  R _mutateUnless<R>(bool unchanged, R Function(C collection) mutation) =>
      unchanged ? mutation(_untrackedValue) : _mutate(mutation);

  void _notifyChanged() {
    _reportChanged();
    _notifySignalUpdate();
  }
}
