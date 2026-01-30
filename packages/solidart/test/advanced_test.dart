import 'package:solidart/advanced.dart';
import 'package:solidart/deps/system.dart' as system;
import 'package:test/test.dart';

class _TestDisposable with DisposableMixin {}

class _TestNode extends system.ReactiveNode
    with DisposableMixin
    implements Configuration {
  _TestNode({required this.autoDispose})
    : super(flags: system.ReactiveFlags.none);

  @override
  final bool autoDispose;

  @override
  Identifier get identifier => throw UnimplementedError();
}

void main() {
  test('DisposableMixin runs cleanup callbacks once', () {
    final disposable = _TestDisposable();
    var calls = 0;

    disposable
      ..onDispose(() => calls++)
      ..onDispose(() => calls++);

    final dispose = disposable.dispose;
    dispose();
    expect(calls, 2);

    // Subsequent dispose should be a no-op.
    dispose();
    expect(calls, 2);
  });

  test('Disposable.unlinkDeps disposes autoDispose deps with no subs', () {
    final dep = _TestNode(autoDispose: true);
    final node = _TestNode(autoDispose: true);
    final link = system.Link(
      version: 0,
      dep: dep,
      sub: node,
    );

    // Set up a minimal dependency link where dep has no subscriber list.
    node
      ..deps = link
      ..depsTail = link;

    Disposable.unlinkDeps(node);

    expect(dep.isDisposed, isTrue);
  });
}
