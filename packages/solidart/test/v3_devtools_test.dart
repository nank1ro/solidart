import 'package:solidart/v3.dart';
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

    signal.value = 1;
    signal.value;

    expect(observer.updated, 1);

    signal.dispose();

    expect(observer.disposed, 1);
  });

  test('trackInDevTools false disables notifications', () {
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    final signal = Signal(0, trackInDevTools: false);

    signal.value = 1;
    signal.value;
    signal.dispose();

    expect(observer.created, 0);
    expect(observer.updated, 0);
    expect(observer.disposed, 0);
  });

  test('trackInDevTools true overrides global disabled default', () {
    SolidartConfig.devToolsEnabled = false;
    final observer = _Observer();
    SolidartConfig.observers.add(observer);

    final signal = Signal(0, trackInDevTools: true);

    expect(observer.created, 1);
  });
}
