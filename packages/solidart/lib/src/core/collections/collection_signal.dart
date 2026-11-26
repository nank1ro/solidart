part of '../core.dart';

/// Whether [elements] is an empty list or set. Only these are checked,
/// because other iterables can run code each time they are iterated.
bool _isEmptyCollection(Iterable<Object?> elements) =>
    (elements is List || elements is Set) && elements.isEmpty;

/// Whether [object] is a NaN double. NaN is not equal to itself, so a
/// collection cannot find it again to undo a write.
bool _isNaN(Object? object) => object is double && object.isNaN;

/// Whether [key] is an immutable value, so a saved undo step can keep it:
/// its equality cannot change after the write.
bool _isValueKey(Object? key) =>
    key == null ||
    key is String ||
    key is bool ||
    key is Enum ||
    (key is num && !key.isNaN);

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
mixin _CollectionSignal<C extends Object> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// A detached copy of [collection], used as the previous value.
  C _copyPrevious(C collection);

  /// The undo step of the last lazy point write. It builds the previous
  /// value from the current collection. Every replacement of the value goes
  /// through [_setPreviousValue], which clears it.
  C Function(C)? _pendingUndo;

  @override
  void _settlePreviousValue() {
    final undo = _pendingUndo;
    // A separate method, so a read with nothing pending allocates no
    // closure.
    if (undo != null) _applyPendingUndo(undo);
  }

  void _applyPendingUndo(C Function(C) undo) {
    final current = _untrackedValue;
    // A callback can read history while its outer mutation is in progress.
    final source = identical(_mutating, current)
        ? _mutatingPrevious ?? current
        : current;
    final previous = untracked(() => undo(source));
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

  /// The check of a nested list resize that threw. The outermost [_mutate]
  /// runs it with its history copy when it ends, because the collection can
  /// be in the middle of a change (for example a `sort`) while it runs.
  bool Function(C, C)? _nestedResizeCheck;

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
    final errors = _FirstError()..run(() => _value = newValue);
    _notifySignalUpdate(errors);
    errors.rethrowIfAny();
    return newValue;
  }

  /// Runs [mutation] on the collection that holds the value.
  ///
  /// If the collection changed, even when [mutation] throws, updates the
  /// previous value and notifies once. A point write saves [undo] until
  /// a reader asks for history. If that write throws after a change, or a
  /// write through the signal runs inside it, the signal drops history,
  /// because [undo] describes only one completed write.
  /// A [_mutate] inside [mutation] on the same collection does not notify:
  /// this one notifies once for both. If [mutation] assigns a new
  /// collection, the assignment notifies, so this one does not.
  ///
  /// Length and nested writes are always checked. Use [slotChanged] for
  /// bounded writes or [bulkCheck] for a full comparison. A list mutation
  /// that can change the length can also move elements and then throw.
  /// In that case, [failedResizeChanged] compares the elements with the
  /// history copy, if one exists. A nested mutation leaves that check to the
  /// outermost one, which runs it on the final collection.
  ///
  /// The error of [mutation] wins over an error of the notification, which
  /// goes to the current [Zone].
  R _mutate<R>(
    R Function(C collection) mutation, {
    bool Function() Function(C, C?)? bulkCheck,
    bool Function()? slotChanged,
    bool Function(C, C)? failedResizeChanged,
    C Function(C)? undo,
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
    final outerResizeCheck = _nestedResizeCheck;
    _nestedChanged = false;
    _nestedResizeCheck = null;
    _mutating = collection;
    if (!nested) _mutatingPrevious = previous;
    late final R result;
    final errors = _FirstError()..run(() => result = mutation(collection));
    final nestedChanged = _nestedChanged;
    final nestedResizeCheck = _nestedResizeCheck;
    _mutating = outer;
    _mutatingPrevious = outerPrevious;
    _nestedChanged = outerChanged;
    _nestedResizeCheck = outerResizeCheck;
    final resizeCheck =
        (errors.hasError ? failedResizeChanged : null) ?? nestedResizeCheck;
    var changed = false;
    errors.run(() {
      if (!identical(_untrackedValue, collection)) return;
      final slotCheck = errors.hasError ? failedSlotChanged ?? check : check;
      changed =
          nestedChanged ||
          length != _lengthOf(collection) ||
          (slotCheck?.call() ?? false) ||
          (!nested &&
              previous != null &&
              (resizeCheck?.call(collection, previous) ?? false));
    });
    if (nested) {
      _nestedChanged |= changed;
      // Leave a failed resize to the outermost mutation that has a copy.
      if (outerPrevious != null) _nestedResizeCheck ??= resizeCheck;
    } else if (changed) {
      if (undo != null && trackPreviousValue) {
        // After an error or a nested write through the signal, [undo] no
        // longer describes the change, so keep no previous value.
        final exact = !errors.hasError && !nestedChanged;
        _storedPreviousValue = null;
        _hasPreviousValue = exact;
        _pendingUndo = exact ? undo : null;
      } else if (previous != null) {
        _setPreviousValue(previous);
      }
      // Separate steps, so a throwing effect does not skip the observers.
      errors
        ..run(_reportChanged)
        ..run(() => _notifySignalUpdate(errors));
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
    C Function(C)? undo,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(
          mutation,
          bulkCheck: bulkCheck,
          slotChanged: slotChanged,
          undo: undo,
        );
}
