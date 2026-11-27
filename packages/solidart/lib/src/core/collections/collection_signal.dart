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

/// Whether every key of type [T] uses built-in equality and hashing.
bool _hasValueKeyType<T>() {
  final keys = <T>[];
  return keys is List<num?> ||
      keys is List<String?> ||
      keys is List<bool?> ||
      keys is List<Enum?>;
}

typedef _ReplacementSlot = ({Object? key, Object? value, bool present});
typedef _CopyReplacement<C> = C Function(Map<Object?, _ReplacementSlot>?);
typedef _CopyReplacementFrom<C> = C Function(
  C,
  Map<Object?, _ReplacementSlot>?,
);

class _ReplacementObservation<C extends Object> {
  _ReplacementObservation.full(this.snapshot) : slots = null;
  _ReplacementObservation.slots(this.slots) : snapshot = null;

  C? snapshot;
  final Map<Object?, _ReplacementSlot>? slots;
}

class _ReplacementBaseline<C extends Object> {
  _ReplacementBaseline(
    this._isIntact,
    this._collection,
    this._copy,
    this._copyOriginal,
    this._originalBulkVersion,
  ) : _activeBulkVersion = _originalBulkVersion;

  final bool Function() _isIntact;
  final C _collection;
  final _CopyReplacementFrom<C> _copy;
  final _CopyReplacement<C>? _copyOriginal;
  final int Function()? _originalBulkVersion;
  int Function()? _activeBulkVersion;
  Option<C>? _committed;
  int? _checkedBulkVersion;
  bool _intact = false;
  bool _captured = false;
  bool _useOriginal = false;
  bool _awaitingObservation = false;
  C? _snapshot;
  ({int Function()? clock, int version})? _snapshotVersion;
  Map<Object?, _ReplacementSlot>? _rewinds;
  Set<alien_system.ReactiveNode>? _changedObservers;
  Set<alien_system.ReactiveNode>? _anchorObservers;
  Map<alien_system.ReactiveNode, _ReplacementObservation<C>>?
  _alternateObservations;
  _ReplacementObservation<C>? _checkedObservation;
  bool _comparisonChanged = false;
  bool _comparing = false;
  bool _forceNotification = false;
  int writeVersion = 0;

  ({C? snapshot, bool notify}) replacementComparison(
    C? snapshot,
    _AlienSignal<C> signal,
    bool Function(C, C) equals,
  ) {
    if (_forceNotification || _comparing) return (snapshot: null, notify: true);
    final changed = _changedObservers;
    if (changed == null) return (snapshot: snapshot, notify: false);
    _ReplacementObservation<C>? alternate;
    Set<_ReplacementObservation<C>>? otherObservations;
    var anchorLive = false;
    for (var link = signal.subs; link != null; link = link.nextSub) {
      if (changed.contains(link.sub)) {
        final observed = _alternateObservations?[link.sub];
        if (observed == null) return (snapshot: null, notify: true);
        if (alternate == null) {
          alternate = observed;
        } else if (!identical(alternate, observed)) {
          (otherObservations ??= Set.identity()).add(observed);
        }
      } else if (_anchorObservers?.contains(link.sub) ?? false) {
        anchorLive = true;
      }
      if (anchorLive && alternate != null) {
        return (snapshot: null, notify: true);
      }
    }
    if (alternate == null) return (snapshot: snapshot, notify: false);
    final observed = _resolveObservation(
      alternate,
      otherObservations,
      snapshot,
      signal,
      equals,
    );
    return (snapshot: observed, notify: observed == null);
  }

  C? _materializeObservation(_ReplacementObservation<C> observed, C? anchor) {
    final snapshot = observed.snapshot;
    if (snapshot != null || anchor == null) return snapshot;
    return observed.snapshot = _copy(anchor, Map.of(observed.slots!));
  }

  C? _resolveObservation(
    _ReplacementObservation<C> alternate,
    Iterable<_ReplacementObservation<C>>? otherObservations,
    C? anchor,
    _AlienSignal<C> signal,
    bool Function(C, C) equals,
  ) {
    final committed = signal.currentValue;
    final pending = signal.pendingValue;
    final first = signal.subs;
    final last = signal.subsTail;
    final writes = writeVersion;
    _comparing = true;
    try {
      final snapshot = untracked<C?>(() {
        final observed = _materializeObservation(alternate, anchor);
        if (observed == null || otherObservations == null) return observed;
        for (final other in otherObservations) {
          final next = _materializeObservation(other, anchor);
          if (next == null || !equals(observed, next)) return null;
        }
        return observed;
      });
      if (!_forceNotification &&
          identical(signal.currentValue, committed) &&
          identical(signal.pendingValue, pending) &&
          identical(signal.subs, first) &&
          identical(signal.subsTail, last) &&
          writeVersion == writes) {
        return snapshot;
      }
      return null;
    } on Object {
      // A failed comparison cannot establish that the observers agree.
      return null;
    } finally {
      _comparing = false;
    }
  }

  void _recordChangedObserver(
    alien_system.ReactiveNode observer,
    _AlienSignal<C> signal, {
    required bool stable,
    required alien_system.Link? newSubscription,
    required Map<Object?, _ReplacementSlot>? rewinds,
    required _ReplacementSlot Function(C, Object?) readSlot,
  }) {
    (_changedObservers ??= Set.identity()).add(observer);
    if (!stable) return;
    if (_anchorObservers == null && newSubscription != null) {
      final anchors = _anchorObservers = Set.identity();
      for (var link = signal.subs; link != null; link = link.nextSub) {
        // An incumbent can get a second link when its dependencies reorder.
        if (!identical(link, newSubscription)) anchors.add(link.sub);
      }
    }
    final anchors = _anchorObservers;
    if (anchors == null || anchors.contains(observer)) return;
    final committed = signal.currentValue;
    final writes = writeVersion;
    final wasComparing = _comparing;
    _comparing = true;
    try {
      final observed =
          _checkedObservation ??
          untracked<_ReplacementObservation<C>>(() {
            if (rewinds == null) {
              return _ReplacementObservation.full(_copy(_collection, null));
            }
            return _ReplacementObservation<C>.slots({
              for (final key in rewinds.keys) key: readSlot(_collection, key),
            });
          });
      if (identical(_committed, committed) &&
          identical(signal.currentValue, committed) &&
          writeVersion == writes) {
        _checkedObservation = observed;
        (_alternateObservations ??= Map.identity())[observer] = observed;
      }
    } on Object {
      // When an observation cannot be copied, keep delivery for its reader.
    } finally {
      _comparing = wasComparing;
    }
  }

  void _forgetDetachedObservation(
    alien_system.ReactiveNode observer,
    alien_system.Link newSubscription,
    _AlienSignal<C> signal,
  ) {
    if (!(_anchorObservers?.contains(observer) ?? false) &&
        !(_changedObservers?.contains(observer) ?? false)) {
      return;
    }
    for (var link = signal.subs; link != null; link = link.nextSub) {
      if (!identical(link, newSubscription) && identical(link.sub, observer)) {
        return;
      }
    }
    _anchorObservers?.remove(observer);
    _changedObservers?.remove(observer);
    _alternateObservations?.remove(observer);
  }

  R runNested<R>(
    R Function(C) mutation,
    C collection,
    int Function()? bulkVersion,
  ) {
    final outerVersion = _activeBulkVersion;
    if (outerVersion == null && bulkVersion == null) {
      return mutation(collection);
    }
    _activeBulkVersion = bulkVersion;
    _checkedBulkVersion = null;
    try {
      return mutation(collection);
    } finally {
      // A nested write may have changed the map without advancing the outer
      // callback's version.
      _activeBulkVersion = outerVersion;
      _checkedBulkVersion = null;
    }
  }

  bool _prepare(Option<C> committed, {bool check = true}) {
    if (!identical(_committed, committed)) {
      _committed = committed;
      _checkedBulkVersion = null;
      _intact = false;
      _captured = false;
      _useOriginal = _copyOriginal != null;
      _awaitingObservation = false;
      _snapshot = null;
      _snapshotVersion = null;
      _rewinds = null;
      _changedObservers = null;
      _anchorObservers = null;
      _alternateObservations = null;
      _checkedObservation = null;
      _forceNotification = false;
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
    required bool equivalent,
  }) {
    if (equivalent) {
      // Establish the baseline before the raw write changes slot identity.
      _prepare(committed);
      return;
    }
    _checkedBulkVersion = null;
    if (slot != null) {
      if (_prepare(committed) && (!_captured || _snapshotVersion != null)) {
        (_rewinds ??= {}).putIfAbsent(slot.key, () => slot);
      }
    } else {
      if (_captured) {
        _snapshotVersion = null;
        _rewinds = null;
      }
      if (observed) {
        capture(committed);
      } else {
        _prepare(committed, check: false);
        if (identical(_committed, committed) && !_captured) {
          // An unobserved write can keep the raw comparison until a read.
          _intact = false;
          _rewinds = null;
          _awaitingObservation = true;
        }
      }
    }
  }

  void recordWriteResult(Option<C> committed) {
    // Identity writes can matter to the surrounding callback even when the
    // replacement comparison is still valid.
    writeVersion++;
    if (identical(_committed, committed) && _captured && _snapshot == null) {
      // A cast view can reject the copy before a nested write repairs it.
      _forceNotification = true;
    }
  }

  C? capture(Option<C> committed) {
    if (_prepare(committed) && !_captured) {
      _captured = true;
      final rewinds = _rewinds;
      _rewinds = null;
      try {
        final snapshot = untracked(
          () => _useOriginal
              ? _copyOriginal!(rewinds)
              : _copy(_collection, rewinds),
        );
        if (identical(_committed, committed)) _snapshot = snapshot;
      } on Object {
        // A failed copy does not prevent the replacement.
      }
    }
    return identical(_committed, committed) ? _snapshot : null;
  }

  void recordRead(
    _AlienSignal<C> signal,
    C value,
    bool Function(C, C) equals,
    bool Function(C, Iterable<_ReplacementSlot>) slotsEqual,
    _ReplacementSlot Function(C, Object?) readSlot, {
    required bool firstObserver,
    required alien_system.ReactiveNode observer,
    required alien_system.Link? newSubscription,
  }) {
    final committed = signal.currentValue;
    final bulkVersion = _activeBulkVersion;
    final version = bulkVersion == null ? null : untracked(bulkVersion);
    final originalBulkVersion = _originalBulkVersion;
    final originalVersion = identical(bulkVersion, originalBulkVersion)
        ? version
        : originalBulkVersion == null
        ? null
        : untracked(originalBulkVersion);
    final readOriginal = originalVersion != null && originalVersion != 0;
    if (readOriginal) _prepare(committed);
    if (!identical(_committed, committed)) return;
    if (_comparing) {
      _forceNotification = true;
      return;
    }
    if (firstObserver) {
      _changedObservers = null;
      _anchorObservers = null;
      _alternateObservations = null;
      _checkedBulkVersion = null;
      _checkedObservation = null;
      _comparisonChanged = false;
      _forceNotification = false;
    }
    if (newSubscription != null) {
      _forgetDetachedObservation(observer, newSubscription, signal);
    }
    final alternate = _alternateObservations?[observer];
    if (_forceNotification ||
        (alternate == null &&
            (_changedObservers?.contains(observer) ?? false))) {
      return;
    }
    if (_awaitingObservation ||
        (firstObserver &&
            (_captured ||
                (_useOriginal && (readOriginal || _rewinds != null))))) {
      _awaitingObservation = false;
      _intact = true;
      _captured = false;
      _useOriginal = false;
      _snapshot = null;
      _snapshotVersion = null;
      _rewinds = null;
      // The bulk mutation can still write after the subscriber reads.
      final writes = writeVersion;
      if (capture(committed) != null &&
          writeVersion == writes &&
          identical(signal.currentValue, committed)) {
        _anchorObservers = Set.identity()..add(observer);
        if (version != null) {
          _snapshotVersion = (clock: bulkVersion, version: version);
        }
      }
      _checkedBulkVersion = version;
      return;
    }
    if (version != null && version == _checkedBulkVersion) {
      if (alternate == null) {
        if (_comparisonChanged) {
          _recordChangedObserver(
            observer,
            signal,
            stable: true,
            newSubscription: newSubscription,
            rewinds: _rewinds,
            readSlot: readSlot,
          );
        } else {
          _anchorObservers?.add(observer);
        }
        return;
      }
      if (identical(alternate, _checkedObservation)) return;
    }
    final snapshot = _useOriginal && readOriginal
        ? capture(committed)
        : _snapshot;
    final snapshotVersion = _snapshotVersion;
    final compareSlots =
        snapshotVersion != null &&
        identical(snapshotVersion.clock, bulkVersion) &&
        snapshotVersion.version == version;
    if (alternate == null && _captured && !compareSlots) {
      _snapshotVersion = null;
      _rewinds = null;
    }
    final rewinds = _rewinds;
    final alternateSlots = alternate?.slots;
    final compareAlternateSlots =
        alternateSlots != null && (!_captured || compareSlots);
    if (alternate == null &&
        rewinds == null &&
        (snapshot == null || compareSlots)) {
      _anchorObservers?.add(observer);
      return;
    }
    final rewindCount = rewinds?.length;
    final writes = writeVersion;
    _checkedBulkVersion = version;
    _checkedObservation = null;
    _comparing = true;
    try {
      final unchanged = untracked(() {
        if (alternate != null) {
          if (compareAlternateSlots) {
            return slotsEqual(value, alternateSlots.values) &&
                (rewinds == null ||
                    slotsEqual(
                      value,
                      rewinds.values.where(
                        (slot) => !alternateSlots.containsKey(slot.key),
                      ),
                    ));
          }
          final observed = _materializeObservation(alternate, snapshot);
          return observed != null && equals(observed, value);
        }
        if (rewinds == null) return equals(snapshot!, value);
        if (!firstObserver) return slotsEqual(value, rewinds.values);
        // Keep slots from writes still in progress, but compare them with
        // what the first subscriber actually read.
        rewinds.updateAll((key, _) => readSlot(value, key));
        return true;
      });
      if (!identical(_committed, committed) ||
          !identical(signal.currentValue, committed)) {
        return;
      }
      final stable = writeVersion == writes;
      final canPruneRewinds =
          stable &&
          unchanged &&
          !_forceNotification &&
          rewinds != null &&
          identical(_rewinds, rewinds) &&
          rewinds.length == rewindCount;
      if (alternate != null) {
        if (stable && unchanged) {
          _comparisonChanged = true;
          _checkedObservation = alternate;
          if (compareAlternateSlots && canPruneRewinds) {
            // Keep the original slots needed to reconstruct the observation.
            rewinds.removeWhere((key, _) => !alternateSlots.containsKey(key));
          }
        } else {
          _checkedBulkVersion = null;
          _alternateObservations!.remove(observer);
        }
        return;
      }
      _comparisonChanged = !unchanged || !stable;
      if (_comparisonChanged) {
        if (!stable) _checkedBulkVersion = null;
        _recordChangedObserver(
          observer,
          signal,
          stable: stable,
          newSubscription: newSubscription,
          rewinds: rewinds,
          readSlot: readSlot,
        );
        return;
      }
      if (firstObserver && rewinds != null) {
        _anchorObservers = Set.identity()..add(observer);
      } else {
        _anchorObservers?.add(observer);
      }
      if (rewinds == null && version != null && !_forceNotification) {
        _snapshotVersion = (clock: bulkVersion, version: version);
      } else if (!firstObserver && canPruneRewinds) {
        // Future writes only need to remember slots that changed again.
        _rewinds = null;
      }
    } on Object {
      // Reading a map can succeed even if comparing it throws. Keep delivery
      // in that case, since we cannot tell what the subscriber observed.
      if (identical(_committed, committed)) _forceNotification = true;
    } finally {
      _comparing = false;
    }
  }
}

/// The mutation logic that [ListSignal], [MapSignal] and [SetSignal] share.
mixin _CollectionSignal<C extends Object> on Signal<C> {
  /// The number of elements or entries in [collection].
  int _lengthOf(C collection);

  /// A detached copy of [collection], used as the previous value.
  C _copyPrevious(C collection);

  /// A replacement changed during a mutation, with its previous value if
  /// it could be copied.
  ({C? previous})? _changedReplacement(C collection) => null;

  /// The undo step of the last lazy point write. It builds the previous
  /// value from the current collection. Every replacement of the value goes
  /// through [_setPreviousValue], which clears it.
  C Function(C)? _pendingUndo;

  /// Whether a read is already rebuilding this signal's history.
  bool _settlingPreviousValue = false;

  @override
  bool get untrackedHasPreviousValue =>
      (!_settlingPreviousValue || _pendingUndo == null) &&
      super.untrackedHasPreviousValue;

  /// The collection length before the pending write.
  int? _pendingPreviousLength;

  String get _previousDescription {
    const previewLimit = 20;
    if ((_pendingPreviousLength ?? 0) > previewLimit) {
      return '<lazy collection history>';
    }
    final previous = _previousValue;
    if (previous == null) return 'null';
    final length = _lengthOf(previous);
    return length > previewLimit ? '<$length elements>' : '$previous';
  }

  @override
  void _settlePreviousValue() {
    final undo = _pendingUndo;
    // A separate method, so a read with nothing pending allocates no
    // closure.
    if (undo != null && !_settlingPreviousValue) {
      _applyPendingUndo(undo);
    }
  }

  void _applyPendingUndo(C Function(C) undo) {
    _settlingPreviousValue = true;
    try {
      var step = undo;
      // One retry settles a superseding write. Repeated writes leave the
      // newest undo available to a later history read.
      for (var attempt = 0; attempt < 2; attempt++) {
        final current = _untrackedValue;
        final previous = untracked(() {
          // A callback can read history after its current write has started.
          final source = identical(_mutating, current)
              ? _mutatingPrevious ?? _mutatingUndo?.call(current) ?? current
              : current;
          return step(source);
        });
        final pending = _pendingUndo;
        if (identical(pending, step)) {
          _setPreviousValue(previous);
          return;
        }
        // A write during the rebuild can install a newer undo step.
        if (pending == null) return;
        step = pending;
      }
    } finally {
      _settlingPreviousValue = false;
    }
  }

  @override
  void _setPreviousValue(C value) {
    _pendingUndo = null;
    _pendingPreviousLength = null;
    super._setPreviousValue(value);
  }

  /// The collection that the current [_mutate] is changing.
  C? _mutating;

  /// The history copy that the outermost [_mutate] took of [_mutating]
  /// before it changed, or null without history.
  C? _mutatingPrevious;

  /// The state of [_mutating] when an assignment restored it.
  ({C snapshot, bool mayCoalesce})? _restoration;

  bool Function(C, C)? get _restoredContentsDiffer => null;

  /// Restores the contents before the current point write.
  C Function(C)? _mutatingUndo;

  /// Captures the original elements of an append before a nested write.
  C Function(C)? _copyPreviousOnNestedWrite;

  void _capturePreviousForNestedWrite(C collection) {
    final copy = _copyPreviousOnNestedWrite;
    if (copy == null) return;
    _copyPreviousOnNestedWrite = null;
    try {
      _mutatingPrevious = untracked(() => copy(collection));
    } on Object {
      // A view with unreadable elements can still be written through.
    }
  }

  /// Whether a mutation nested in the current [_mutate] changed the
  /// collection.
  bool _nestedChanged = false;

  /// Saves the committed map while an update can still write to it.
  _ReplacementBaseline<C>? _replacementBaseline;

  void _rememberReplacementWrite(
    C collection,
    _ReplacementSlot? slot, {
    bool equivalent = false,
  }) {
    final baseline = _replacementBaseline;
    if (baseline == null || _internalSignal.forceDirty) return;
    final committed = _internalSignal.currentValue;
    if (identical(collection, committed.safeUnwrap())) {
      baseline.rememberWrite(
        committed,
        slot,
        observed: _internalSignal.subs != null,
        equivalent: equivalent,
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
            ? _restoration?.snapshot ?? _mutatingPrevious ?? _copyPrevious(old)
            : old,
      );
    }
    if (identical(newValue, _mutating) &&
        !identical(newValue, old) &&
        _restoredContentsDiffer != null) {
      _restoration = null;
      try {
        final snapshot = untracked(() => _copyPrevious(newValue));
        final signal = _internalSignal;
        _restoration = (
          snapshot: snapshot,
          mayCoalesce:
              !signal.forceDirty &&
              identical(signal.currentValue.safeUnwrap(), newValue),
        );
      } on Object {
        // An unreadable cast view can still be restored.
      }
    }
    _setValueAndNotify(newValue);
    return newValue;
  }

  /// Runs [mutation] on the collection that holds the value.
  ///
  /// If the collection changed, even when [mutation] throws, updates the
  /// previous value and notifies once. A point write saves [undo] until
  /// a reader asks for history. If that write throws after a change, or a
  /// write through the signal runs inside it, the signal drops history
  /// unless [copyPreviousOnNestedWrite] captured the original contents.
  /// [undoDuringWrite] restores the contents before an in-progress write
  /// so a callback can read history from the preceding write.
  /// A [_mutate] inside [mutation] on the same collection does not notify:
  /// this one notifies once for both. If [mutation] assigns a new
  /// collection, the assignment notifies. A later change to the replacement
  /// can notify separately. A restored list compares from the point at
  /// which the assignment restored it.
  ///
  /// Length and nested writes are always checked. Use [slotChanged] for
  /// bounded writes or [bulkCheck] for a full comparison. A list mutation
  /// that can change the length can also move elements and then throw.
  /// Set [comparesAllElements] if the bulk check also covers nested resizes.
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
    C Function(C)? undoDuringWrite,
    C Function(C)? copyPreviousOnNestedWrite,
    bool Function()? failedSlotChanged,
    _CopyReplacementFrom<C>? copyReplacementBaseline,
    _CopyReplacement<C>? copyOriginalReplacementBaseline,
    int Function(int)? bulkVersion,
    _ReplacementSlot? replacementSlot,
    bool deferReplacementWrite = false,
    bool equivalentReplacementWrite = false,
    bool keepBulkVersion = false,
    bool comparesAllElements = false,
  }) {
    final collection = _untrackedValue;
    final outer = _mutating;
    final nested = identical(collection, outer);
    final outerBaseline = _replacementBaseline;
    if (nested) _capturePreviousForNestedWrite(collection);
    if (nested && !deferReplacementWrite) {
      _rememberReplacementWrite(
        collection,
        replacementSlot,
        equivalent: equivalentReplacementWrite,
      );
    }
    final length = _lengthOf(collection);
    final readBulkVersion = bulkVersion == null
        ? null
        : () => bulkVersion(length);
    var previous = !nested && trackPreviousValue && undo == null
        ? _copyPrevious(collection)
        : null;
    final check = slotChanged ?? bulkCheck?.call(collection, previous);
    final outerChanged = _nestedChanged;
    final outerPrevious = _mutatingPrevious;
    final outerRestoration = _restoration;
    final outerUndo = _mutatingUndo;
    final outerCopy = _copyPreviousOnNestedWrite;
    final outerResizeCheck = _nestedResizeCheck;
    _nestedChanged = false;
    _nestedResizeCheck = null;
    _mutating = collection;
    if (!nested) {
      _mutatingPrevious = previous;
      _restoration = null;
      _mutatingUndo = undoDuringWrite;
      _copyPreviousOnNestedWrite = copyPreviousOnNestedWrite;
      _replacementBaseline = copyReplacementBaseline == null
          ? null
          : _ReplacementBaseline(
              () =>
                  length == _lengthOf(collection) && !(check?.call() ?? false),
              collection,
              copyReplacementBaseline,
              copyOriginalReplacementBaseline,
              readBulkVersion,
            );
    }
    late final R result;
    final errors = _FirstError()
      ..run(() {
        result = nested && outerBaseline != null && !keepBulkVersion
            ? outerBaseline.runNested(mutation, collection, readBulkVersion)
            : mutation(collection);
      });
    final nestedChanged = _nestedChanged;
    final nestedResizeCheck = _nestedResizeCheck;
    final restoration = nested ? null : _restoration;
    _mutating = outer;
    if (!nested) {
      previous = _mutatingPrevious;
      _mutatingPrevious = outerPrevious;
      _mutatingUndo = outerUndo;
      _copyPreviousOnNestedWrite = outerCopy;
    }
    _nestedChanged = outerChanged;
    _nestedResizeCheck = outerResizeCheck;
    _replacementBaseline = outerBaseline;
    if (!nested) _restoration = outerRestoration;
    final resizeCheck =
        (errors.hasError ? failedResizeChanged : null) ?? nestedResizeCheck;
    var changed = false;
    ({C? previous})? replacementChange;
    var changedAfterRestore = false;
    errors.run(() {
      if (!nested) replacementChange = _changedReplacement(collection);
      if (!identical(_untrackedValue, collection)) return;
      if (restoration != null) {
        changedAfterRestore = untracked(
          () => _restoredContentsDiffer!(collection, restoration.snapshot),
        );
        if (changedAfterRestore || !restoration.mayCoalesce) {
          changed = changedAfterRestore;
          return;
        }
      }
      final slotCheck = errors.hasError ? failedSlotChanged ?? check : check;
      changed =
          nestedChanged ||
          length != _lengthOf(collection) ||
          (slotCheck?.call() ?? false) ||
          (!nested &&
              !comparesAllElements &&
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
    } else if (changed && restoration != null && !changedAfterRestore) {
      // A deferred restoration can compare equal to the committed backing.
      // Deliver the earlier write without replacing the assignment's history.
      errors.run(_reportChanged);
    } else if (changed || replacementChange != null) {
      if (replacementChange case final replacement?) {
        if (replacement.previous case final before?) _setPreviousValue(before);
      } else if (restoration != null) {
        _setPreviousValue(restoration.snapshot);
      } else if (previous != null) {
        _setPreviousValue(previous);
      } else if (undo != null && trackPreviousValue) {
        // After an error or a nested write through the signal, [undo] no
        // longer describes the change, so keep no previous value.
        final exact = !errors.hasError && !nestedChanged;
        _storedPreviousValue = null;
        _hasPreviousValue = exact;
        _pendingUndo = exact ? undo : null;
        _pendingPreviousLength = exact ? length : null;
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
    bool equivalentReplacementWrite = false,
  }) => unchanged
      ? mutation(_untrackedValue)
      : _mutate(
          mutation,
          bulkCheck: bulkCheck,
          slotChanged: slotChanged,
          undo: undo,
          replacementSlot: replacementSlot,
          equivalentReplacementWrite: equivalentReplacementWrite,
          keepBulkVersion: equivalentReplacementWrite,
        );
}
