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

typedef _ReplacementSlot = ({Object? key, Object? value, bool present});
typedef _CopyReplacement<C> = C Function(Map<Object?, _ReplacementSlot>?);

class _ReplacementBaseline<C extends Object> {
  _ReplacementBaseline(
    this._isIntact,
    this._copy,
    this._copyOriginal,
    this._originalMayHaveChanged,
  );

  final bool Function() _isIntact;
  final _CopyReplacement<C> _copy;
  final _CopyReplacement<C>? _copyOriginal;
  final bool Function()? _originalMayHaveChanged;
  Option<C>? _committed;
  bool _intact = false;
  bool _captured = false;
  bool _useOriginal = false;
  bool _awaitingObservation = false;
  C? _snapshot;
  Map<Object?, _ReplacementSlot>? _rewinds;
  bool observedChange = false;

  bool _prepare(Option<C> committed, {bool check = true}) {
    if (!identical(_committed, committed)) {
      _committed = committed;
      _intact = false;
      _captured = false;
      _useOriginal = _copyOriginal != null;
      _awaitingObservation = false;
      _snapshot = null;
      _rewinds = null;
      observedChange = false;
      try {
        final intact = check && (_useOriginal || untracked(_isIntact));
        if (identical(_committed, committed)) _intact = intact;
      } on Object {
        // An unreadable cast view can still be replaced.
      }
    }
    return identical(_committed, committed) && _intact;
  }

  void rememberWrite(
    Option<C> committed,
    _ReplacementSlot? slot, {
    required bool observed,
  }) {
    if (slot != null) {
      if (_prepare(committed) && !_captured) {
        (_rewinds ??= {}).putIfAbsent(slot.key, () => slot);
      }
    } else if (observed) {
      capture(committed);
    } else {
      _prepare(committed, check: false);
      if (identical(_committed, committed) && !_captured) {
        // An unobserved write can keep the raw comparison. If a subscriber
        // reads later, that read establishes a new baseline.
        _intact = false;
        _rewinds = null;
        _awaitingObservation = true;
      }
    }
  }

  void recordWriteResult(Option<C> committed) {
    if (identical(_committed, committed) && _captured && _snapshot == null) {
      // A cast view can reject the copy before a nested write repairs it.
      observedChange = true;
    }
  }

  C? capture(Option<C> committed) {
    if (_prepare(committed) && !_captured) {
      _captured = true;
      final rewinds = _rewinds;
      _rewinds = null;
      try {
        final copy = _useOriginal ? _copyOriginal! : _copy;
        final snapshot = untracked(() => copy(rewinds));
        if (identical(_committed, committed)) _snapshot = snapshot;
      } on Object {
        // A failed copy does not prevent the replacement.
      }
    }
    return identical(_committed, committed) ? _snapshot : null;
  }

  void recordRead(
    Option<C> committed,
    C value,
    bool Function(C, C) equals,
    bool Function(C, Iterable<_ReplacementSlot>) slotsEqual,
    _ReplacementSlot Function(C, Object?) readSlot, {
    required bool firstObserver,
  }) {
    final readOriginal =
        _copyOriginal != null && (_originalMayHaveChanged?.call() ?? true);
    if (readOriginal) _prepare(committed);
    if (observedChange || !identical(_committed, committed)) return;
    if (_awaitingObservation ||
        (firstObserver && _useOriginal && readOriginal)) {
      _awaitingObservation = false;
      _intact = true;
      _captured = false;
      _useOriginal = false;
      _rewinds = null;
      // The bulk mutation can still write after the subscriber reads.
      capture(committed);
      return;
    }
    final snapshot = _useOriginal && readOriginal
        ? capture(committed)
        : _snapshot;
    final rewinds = _rewinds;
    if (snapshot == null && rewinds == null) return;
    // A comparer can reenter this read. Keep the notification if it throws.
    observedChange = true;
    try {
      final unchanged = untracked(() {
        if (rewinds == null) return equals(snapshot!, value);
        if (!firstObserver) return slotsEqual(value, rewinds.values);
        // Keep slots from writes still in progress, but compare them with
        // what the first subscriber actually read.
        rewinds.updateAll((key, _) => readSlot(value, key));
        return true;
      });
      if (identical(_committed, committed)) observedChange = !unchanged;
    } on Object {
      // Reading a map can succeed even if comparing it throws.
    }
  }
}

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

  /// Saves the committed map while an update can still write to it.
  _ReplacementBaseline<C>? _replacementBaseline;

  void _rememberReplacementWrite(C collection, _ReplacementSlot? slot) {
    final baseline = _replacementBaseline;
    if (baseline == null || _internalSignal.forceDirty) return;
    final committed = _internalSignal.currentValue;
    if (identical(collection, committed.safeUnwrap())) {
      baseline.rememberWrite(
        committed,
        slot,
        observed: _internalSignal.subs != null,
      );
    }
  }

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
    _setValueAndNotify(newValue);
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
    C Function(C, Map<Object?, _ReplacementSlot>?)? copyReplacementBaseline,
    _CopyReplacement<C>? copyOriginalReplacementBaseline,
    bool Function()? originalMayHaveChanged,
    _ReplacementSlot? replacementSlot,
  }) {
    final collection = _untrackedValue;
    final outer = _mutating;
    final nested = identical(collection, outer);
    final outerBaseline = _replacementBaseline;
    if (nested) _rememberReplacementWrite(collection, replacementSlot);
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
    if (!nested) {
      _mutatingPrevious = previous;
      _replacementBaseline = copyReplacementBaseline == null
          ? null
          : _ReplacementBaseline(
              () =>
                  length == _lengthOf(collection) && !(check?.call() ?? false),
              (slots) => copyReplacementBaseline(collection, slots),
              copyOriginalReplacementBaseline,
              originalMayHaveChanged,
            );
    }
    late final R result;
    final errors = _FirstError()..run(() => result = mutation(collection));
    final nestedChanged = _nestedChanged;
    final nestedResizeCheck = _nestedResizeCheck;
    _mutating = outer;
    _mutatingPrevious = outerPrevious;
    _nestedChanged = outerChanged;
    _nestedResizeCheck = outerResizeCheck;
    _replacementBaseline = outerBaseline;
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
      if (changed) {
        outerBaseline?.recordWriteResult(_internalSignal.currentValue);
      }
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
    _ReplacementSlot? replacementSlot,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(
          mutation,
          bulkCheck: bulkCheck,
          slotChanged: slotChanged,
          undo: undo,
          replacementSlot: replacementSlot,
        );
}
