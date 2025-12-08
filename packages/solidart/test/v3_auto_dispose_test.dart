import 'package:solidart/deps/system.dart' as system;
import 'package:solidart/v3.dart';
import 'package:test/test.dart';

void main() {
  late bool previousAutoDispose;

  setUp(() {
    previousAutoDispose = SolidartConifg.autoDispose;
    SolidartConifg.autoDispose = true;
  });

  tearDown(() {
    SolidartConifg.autoDispose = previousAutoDispose;
  });

  test('disposing a signal cascades to its dependents', () {
    final a = Signal(0);
    final b = Computed(() => a.value * 2);
    final c = Effect(() {
      b.value;
    });
    final d = Signal(0);
    final e = Effect(() {
      a.value;
      d.value;
    });

    a.dispose();

    expect(a.isDisposed, isTrue);
    expect(b.isDisposed, isTrue);
    expect(c.isDisposed, isTrue);
    expect(e.isDisposed, isFalse);
    expect(d.isDisposed, isFalse);

    final deps = _depsOf(e);
    expect(deps.contains(a), isFalse);
    expect(deps.contains(d), isTrue);
  });

  test(
    'disposing a computed cleans subscribers but keeps shared deps alive',
    () {
      final a = Signal(0);
      final b = Computed(() => a.value * 2);
      final c = Effect(() {
        b.value;
      });
      final e = Effect(() {
        a.value;
      });

      b.dispose();

      expect(b.isDisposed, isTrue);
      expect(c.isDisposed, isTrue);
      expect(a.isDisposed, isFalse);
      expect(e.isDisposed, isFalse);
    },
  );

  test(
    'disposing an effect detaches dependencies and triggers auto dispose',
    () {
      final a = Signal(0);
      final b = Computed(() => a.value + 1);
      final c = Effect(() {
        b.value;
      });
      final e = Effect(() {
        a.value;
      });

      c.dispose();

      expect(c.isDisposed, isTrue);
      expect(b.isDisposed, isTrue);
      expect(a.isDisposed, isFalse);
      expect(e.isDisposed, isFalse);
      expect(_depsOf(e).contains(a), isTrue);
    },
  );

  test('respects explicit autoDispose false', () {
    final a = Signal(0);
    final b = Computed(() => a.value + 1, autoDispose: false);
    final c = Effect(() {
      b.value;
    }, autoDispose: false);

    a.dispose();

    expect(a.isDisposed, isTrue);
    expect(b.isDisposed, isFalse);
    expect(c.isDisposed, isFalse);
    expect(_depsOf(b), isEmpty);
    expect(_depsOf(c), isNotEmpty);
  });

  test('global autoDispose off but explicit opt-in still disposes', () {
    SolidartConifg.autoDispose = false;
    final a = Signal(0, autoDispose: true);
    final b = Computed(() => a.value + 1, autoDispose: true);
    final c = Effect(() {
      b.value;
    }, autoDispose: true);
    final d = Effect(() {
      a.value;
    }, autoDispose: false);

    a.dispose();

    expect(a.isDisposed, isTrue);
    expect(b.isDisposed, isTrue);
    expect(c.isDisposed, isTrue);
    expect(d.isDisposed, isFalse);
    expect(_depsOf(d), isEmpty);
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
