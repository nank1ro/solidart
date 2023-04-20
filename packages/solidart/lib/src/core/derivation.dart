// ignore_for_file: public_member_api_docs

import 'package:meta/meta.dart';
import 'package:solidart/src/core/atom.dart';
import 'package:solidart/src/utils.dart';

/// The state of the derivation
enum DerivationState {
  /// Before being run or (outside batch and not being observed)
  /// at this point derivation is not holding any data about dependency tree
  notTracking,

  /// No shallow dependency changed since last computation
  /// won't recalculate derivation this is what makes the derivation fast
  upToDate,

  /// Some deep dependency changed, but don't know if shallow dependency changed
  /// will require to check first if UP_TO_DATE or POSSIBLY_STALE
  /// currently only Computed will propagate POSSIBLY_STALE
  ///
  /// Having this state is second big optimization:
  /// don't have to recompute on every dependency change, but only when it's
  /// needed
  possiblyStale,

  /// A shallow dependency has changed since last computation and the derivation
  /// will need to recompute when it's needed next.
  stale
}

abstract class Derivation {
  late Set<Atom> observables;
  Set<Atom>? newObservables;

  SolidartCaughtException? errorValue;

  @internal
  late DerivationState dependenciesState;

  void onBecomeStale();

  void suspend();
}
