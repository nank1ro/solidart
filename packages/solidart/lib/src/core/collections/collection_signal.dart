part of '../core.dart';

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
mixin _CollectionSignal<C extends Object> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// A detached copy of [collection], used as the previous value.
  C _copyPrevious(C collection);

  /// Saves what a bulk mutation of [collection] must compare. Returns a
  /// function that tells, after the mutation, whether an element or entry
  /// is no longer `identical` to the one at the same position before.
  /// [previous] is the history copy, or null without history.
  bool Function() _bulkChangeCheck(C collection, C? previous);

  /// The collection that the current [_mutate] is changing.
  C? _mutating;

  @override
  C setValue(C newValue) {
    final old = _untrackedValue;
    if (_compare(old, newValue)) {
      return newValue;
    }
    if (trackPreviousValue) {
      // An outer [_mutate] may still change the outgoing collection.
      _setPreviousValue(identical(old, _mutating) ? _copyPrevious(old) : old);
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
  /// the collection only when it changes its length. Set [slotChanged] when
  /// [mutation] can change only one slot: it tells whether that slot
  /// changed. Then no full comparison is made. Other mutations can run code
  /// of the caller, so they use [_bulkChangeCheck].
  ///
  /// The error of [mutation] wins over an error of the notification, which
  /// goes to the current [Zone].
  R _mutate<R>(
    R Function(C collection) mutation, {
    bool resizes = false,
    bool Function()? slotChanged,
  }) {
    final collection = _untrackedValue;
    if (identical(collection, _mutating)) return mutation(collection);
    final outer = _mutating;
    final length = _lengthOf(collection);
    final previous = trackPreviousValue ? _copyPrevious(collection) : null;
    final check = resizes
        ? null
        : slotChanged ?? _bulkChangeCheck(collection, previous);
    late final R result;
    _mutating = collection;
    final errors = _FirstError()..run(() => result = mutation(collection));
    _mutating = outer;
    var changed = false;
    errors.run(() {
      if (!identical(_untrackedValue, collection)) return;
      changed = length != _lengthOf(collection);
      if (changed) return;
      if (check != null) {
        changed = check();
      } else if (errors.hasError && previous != null && collection is List) {
        // A failed list resize can shift elements before the length changes.
        changed = _bulkChangeCheck(collection, previous)();
      }
    });
    if (changed) {
      if (previous != null) errors.run(() => _setPreviousValue(previous));
      errors.run(_notifyChanged);
    }
    errors.rethrowIfAny();
    return result;
  }

  /// Runs [mutation] like [_mutate], or directly on the collection when
  /// [unchanged] is true, so the collection is not copied or compared. The
  /// collection still runs [mutation], so it throws like a plain collection.
  R _mutateUnless<R>(
    bool unchanged,
    R Function(C collection) mutation, {
    bool resizes = false,
    bool Function()? slotChanged,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(mutation, resizes: resizes, slotChanged: slotChanged);

  void _notifyChanged() {
    _reportChanged();
    _notifySignalUpdate();
  }
}
