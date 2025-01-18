// ignore_for_file: public_member_api_docs
part of 'core.dart';

/// {@template atom}
/// Creates a simple Atom for tracking its usage in a reactive context. This is
/// useful when you don't need the value but instead a way of knowing when it
//// becomes active and inactive in a reaction.
/// {@endtemplate}
@internal
class Atom with alien.Dependency {
  /// {@macro atom}
  Atom({required this.name});

  final String name;

  bool disposed = false;

  bool get hasObservers => subs != null;

  // coverage:ignore-start
  void dispose() {}
  // coverage:ignore-end
}
