import 'package:solidart/deps/system.dart' as system;
import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  test('Effect runs immediately and reacts to dependency changes', () {
    final count = Signal(0);
    var runs = 0;

    Effect(() {
      count.value;
      runs++;
    });

    expect(runs, 1);

    count.value = 1;
    expect(runs, 2);

    // Setting the same value should be ignored
    count.value = 1;
    expect(runs, 2);
  });

  test('Effect.manual is lazy until run is called', () {
    final count = Signal(0);
    var runs = 0;

    final effect = Effect.manual(() {
      count.value;
      runs++;
    });

    // No run yet, so nothing tracked
    count.value = 1;
    expect(runs, 0);

    effect.run();
    expect(runs, 1);

    count.value = 2;
    expect(runs, 2);
  });

  test('dispose stops reactions and detaches dependencies', () {
    final count = Signal(0);
    var runs = 0;

    final effect = Effect(() {
      count.value;
      runs++;
    });

    expect(_depsOf(effect), contains(count));

    effect.dispose();

    expect(effect.isDisposed, isTrue);
    expect(_depsOf(effect), isEmpty);

    count.value = 1;
    expect(runs, 1);
  });

  test(
    'nested effects attach to parent by default and auto dispose with it',
    () {
      final previousAutoDispose = SolidartConfig.autoDispose;
      SolidartConfig.autoDispose = true;
      addTearDown(() {
        SolidartConfig.autoDispose = previousAutoDispose;
      });

      late Effect child;
      final parent = Effect(() {
        child = Effect(() {});
      });

      expect(_depsOf(parent), contains(child));

      parent.dispose();

      expect(parent.isDisposed, isTrue);
      expect(child.isDisposed, isTrue);
    },
  );

  test('detached effects stay alive when parent is disposed', () {
    final previousAutoDispose = SolidartConfig.autoDispose;
    final previousDetachEffects = SolidartConfig.detachEffects;
    SolidartConfig.autoDispose = true;
    SolidartConfig.detachEffects = false;
    addTearDown(() {
      SolidartConfig.autoDispose = previousAutoDispose;
      SolidartConfig.detachEffects = previousDetachEffects;
    });

    final source = Signal(0);
    var childRuns = 0;
    late Effect child;
    final parent = Effect(() {
      child = Effect(() {
        source.value;
        childRuns++;
      }, detach: true);
      source.value;
    });

    expect(_depsOf(parent), isNot(contains(child)));

    parent.dispose();

    expect(parent.isDisposed, isTrue);
    expect(child.isDisposed, isFalse);

    source.value = 1;
    expect(childRuns, 2); // initial run + one more after change

    child.dispose();
  });

  test('global detachEffects detaches nested effects by default', () {
    final previousAutoDispose = SolidartConfig.autoDispose;
    final previousDetachEffects = SolidartConfig.detachEffects;
    SolidartConfig.autoDispose = true;
    SolidartConfig.detachEffects = true;
    addTearDown(() {
      SolidartConfig.autoDispose = previousAutoDispose;
      SolidartConfig.detachEffects = previousDetachEffects;
    });

    late Effect child;
    final parent = Effect(() {
      child = Effect(() {});
    });

    expect(_depsOf(parent), isNot(contains(child)));

    parent.dispose();
    expect(parent.isDisposed, isTrue);
    expect(child.isDisposed, isFalse);

    child.dispose();
  });

}

List<system.ReactiveNode> _depsOf(system.ReactiveNode node) {
  final deps = <system.ReactiveNode>[];
  var link = node.deps;
  while (link != null) {
    deps.add(link.dep);
    link = link.nextDep;
  }
  return deps;
}
