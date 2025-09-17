// ignore_for_file: public_member_api_docs, document_ignores

import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:meta/meta.dart';

class SignalWatcher extends StatelessWidget {
  const SignalWatcher({super.key, required this.builder, this.child});

  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);

  @override
  @internal
  StatelessElement createElement() => _SignalWatcherElement(this);
}

class _SignalWatcherElement extends StatelessElement {
  _SignalWatcherElement(SignalWatcher super.widget);

  late final effect =
      Effect(scheduler, detach: true, autoDispose: false, autorun: false);

  void scheduler() {
    if (dirty) return;
    markNeedsBuild();
  }

  @override
  void unmount() {
    super.unmount();
    effect.dispose();
  }

  @override
  Widget build() {
    final prevSub = reactiveSystem.activeSub;
    // ignore: invalid_use_of_protected_member
    reactiveSystem.activeSub = effect.subscriber;

    try {
      return super.build();
    } finally {
      reactiveSystem.activeSub = prevSub;
    }
  }
}
