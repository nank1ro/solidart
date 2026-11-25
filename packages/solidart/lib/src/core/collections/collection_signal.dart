part of '../core.dart';

/// Whether [elements] is an empty list or set. Only these are checked,
/// because other iterables can run code each time they are iterated.
bool _isEmptyCollection(Iterable<Object?> elements) =>
    (elements is List || elements is Set) && elements.isEmpty;

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
mixin _CollectionSignal<C extends Object> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// A detached copy of [collection], used as the previous value.
  C _copyPrevious(C collection);

  /// The undo step of the last lazy point write. Applied to a copy of the
  /// current collection, it gives the previous value. Every replacement of
  /// the value goes through [_setPreviousValue], which clears it.
  void Function(C)? _pendingUndo;

  @override
  void _settlePreviousValue() {
    final undo = _pendingUndo;
    if (undo == null) return;
    final current = _untrackedValue;
    // A callback can read history while its outer mutation is in progress.
    final source = identical(_mutating, current)
        ? _mutatingPrevious ?? current
        : current;
    final previous = untracked(() {
      final copy = _copyPrevious(source);
      undo(copy);
      return copy;
    });
    if (identical(_pendingUndo, undo)) _setPreviousValue(previous);
  }

  @override
  void _setPreviousValue(C value) {
    _pendingUndo = null;
    super._setPreviousValue(value);
  }

  /// The collection that the current [_mutate] is changing.
  C? _mutating;

  /// The history copy that the outermost [_mutate] took of [_mutating]
  /// before it changed, or null without history.
  C? _mutatingPrevious;

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
      // An outer [_mutate] may already have changed the outgoing
      // collection, and may still change it. So use its copy from before.
      _setPreviousValue(
        identical(old, _mutating)
            ? _mutatingPrevious ?? _copyPrevious(old)
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
  /// If the collection changed, even when [mutation] throws, updates the
  /// previous value and notifies once. A point write saves [undo] until
  /// a reader asks for history. If that write throws after a change, the
  /// signal drops history because [undo] describes a completed write.
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
    void Function(C)? undo,
    bool Function()? failedSlotChanged,
  }) {
    final collection = _untrackedValue;
    final outer = _mutating;
    final nested = identical(collection, outer);
    final length = _lengthOf(collection);
    final previous = !nested && trackPreviousValue && undo == null
        ? _copyPrevious(collection)
        : null;
    final check = slotChanged ?? bulkCheck?.call(collection, previous);
    final outerChanged = _nestedChanged;
    final outerPrevious = _mutatingPrevious;
    _nestedChanged = false;
    _mutating = collection;
    if (!nested) _mutatingPrevious = previous;
    late final R result;
    final errors = _FirstError()..run(() => result = mutation(collection));
    final nestedChanged = _nestedChanged;
    _mutating = outer;
    _mutatingPrevious = outerPrevious;
    _nestedChanged = outerChanged;
    var changed = false;
    errors.run(() {
      if (!identical(_untrackedValue, collection)) return;
      final slotCheck = errors.hasError ? failedSlotChanged ?? check : check;
      final resizeSnapshot = nested ? outerPrevious : previous;
      changed =
          nestedChanged ||
          length != _lengthOf(collection) ||
          (slotCheck?.call() ?? false) ||
          (errors.hasError &&
              resizeSnapshot != null &&
              (failedResizeChanged?.call(collection, resizeSnapshot) ?? false));
    });
    if (nested) {
      _nestedChanged |= changed;
    } else if (changed) {
      if (undo != null && trackPreviousValue) {
        _storedPreviousValue = null;
        _hasPreviousValue = !errors.hasError;
        _pendingUndo = errors.hasError ? null : undo;
      } else if (previous != null) {
        _setPreviousValue(previous);
      }
      // Separate steps, so a throwing effect does not skip the observers.
      errors
        ..run(_reportChanged)
        ..run(_notifySignalUpdate);
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
    void Function(C)? undo,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(
          mutation,
          bulkCheck: bulkCheck,
          slotChanged: slotChanged,
          undo: undo,
        );
}
