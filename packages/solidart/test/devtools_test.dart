import 'package:solidart/solidart.dart';
import 'package:test/test.dart';

class _Observer implements SolidartObserver {
  int created = 0;
  int updated = 0;
  int disposed = 0;

  @override
  void didCreateSignal(ReadonlySignal<Object?> signal) {
    created++;
  }

  @override
  void didUpdateSignal(ReadonlySignal<Object?> signal) {
    updated++;
  }

  @override
  void didDisposeSignal(ReadonlySignal<Object?> signal) {
    disposed++;
  }
}

class _ConstObserver extends SolidartObserver {
  const _ConstObserver();

  @override
  void didCreateSignal(ReadonlySignal<Object?> signal) {}

  @override
  void didUpdateSignal(ReadonlySignal<Object?> signal) {}

  @override
  void didDisposeSignal(ReadonlySignal<Object?> signal) {}
}

void main() {
  late bool previousDevToolsEnabled;
  late List<SolidartObserver> previousObservers;

  setUp(() {
    previousDevToolsEnabled = SolidartConfig.devToolsEnabled;
    previousObservers = List.of(SolidartConfig.observers);
    SolidartConfig.devToolsEnabled = true;
    SolidartConfig.observers.clear();
  });

  tearDown(() {
    SolidartConfig.devToolsEnabled = previousDevToolsEnabled;
    SolidartConfig.observers
      ..clear()
      ..addAll(previousObservers);
  });

  test('notifies observers on create/update/dispose', () {
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    final signal = Signal(0);

    expect(observer.created, 1);
    expect(observer.updated, 0);
    expect(observer.disposed, 0);

    signal
      ..value = 1
      ..value;

    expect(observer.updated, 1);

    signal.dispose();

    expect(observer.disposed, 1);
  });

  test('trackInDevTools false disables notifications', () {
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    Signal(0, trackInDevTools: false)
      ..value = 1
      ..value
      ..dispose();

    expect(observer.created, 0);
    expect(observer.updated, 0);
    expect(observer.disposed, 0);
  });

  test('trackInDevTools true overrides global disabled default', () {
    SolidartConfig.devToolsEnabled = false;
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    final _ = Signal(0, trackInDevTools: true);

    expect(observer.created, 1);
  });

  test('SolidartObserver supports const subclasses', () {
    const observer = _ConstObserver();
    expect(observer, isA<SolidartObserver>());
  });

  test('Computed participates in DevTools events', () {
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    final source = Signal(1);
    final computed = Computed(() => source.value * 2);

    // Verify creation events for both source and computed.
    expect(observer.created, 2);

    expect(computed.value, 2);
    final updatedAfterFirstRead = observer.updated;

    source.value = 2;
    expect(source.value, 2);
    final updatedAfterSource = observer.updated;
    expect(updatedAfterSource, greaterThan(updatedAfterFirstRead));

    expect(computed.value, 4);
    expect(observer.updated, greaterThan(updatedAfterSource));

    source.dispose();
    computed.dispose();
  });
}
