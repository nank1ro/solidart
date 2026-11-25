part of '../core.dart';

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
mixin _CollectionSignal<C extends Object> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// A detached copy of [collection], used as the previous value.
  C _copyPrevious(C collection);

  /// The collection that the current [_mutate] is changing.
  C? _mutating;

  /// Whether a mutation nested in the current [_mutate] changed the
  /// collection.
  bool _nestedChanged = false;

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
  /// Length and nested writes are always checked. Use [slotChanged] for
  /// bounded writes or [bulkCheck] for a full comparison. A list mutation
  /// that can change the length can also move elements and then throw.
  /// In that case, [failedResizeChanged] compares the elements with the
  /// history copy, if one exists.
  ///
  /// The error of [mutation] wins over an error of the notification, which
  /// goes to the current [Zone].
  R _mutate<R>(
    R Function(C collection) mutation, {
    bool Function() Function(C, C?)? bulkCheck,
    bool Function()? slotChanged,
    bool Function(C, C)? failedResizeChanged,
  }) {
    final collection = _untrackedValue;
    final outer = _mutating;
    final nested = identical(collection, outer);
    final length = _lengthOf(collection);
    final previous = !nested && trackPreviousValue
        ? _copyPrevious(collection)
        : null;
    final check = slotChanged ?? bulkCheck?.call(collection, previous);
    final outerChanged = _nestedChanged;
    _nestedChanged = false;
    _mutating = collection;
    late final R result;
    final errors = _FirstError()..run(() => result = mutation(collection));
    final nestedChanged = _nestedChanged;
    _mutating = outer;
    _nestedChanged = outerChanged;
    var changed = false;
    errors.run(() {
      if (!identical(_untrackedValue, collection)) return;
      changed =
          nestedChanged ||
          length != _lengthOf(collection) ||
          (check?.call() ?? false) ||
          (errors.hasError &&
              previous != null &&
              (failedResizeChanged?.call(collection, previous) ?? false));
    });
    if (nested) {
      _nestedChanged |= changed;
    } else if (changed) {
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
    bool Function() Function(C, C?)? bulkCheck,
    bool Function()? slotChanged,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(mutation, bulkCheck: bulkCheck, slotChanged: slotChanged);

  void _notifyChanged() {
    _reportChanged();
    _notifySignalUpdate();
  }
}
