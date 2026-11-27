import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:solidart/solidart.dart';

void main() {
  SolidartConfig.devToolsEnabled = true;
  final observer = _Observer();
  SolidartConfig.observers.add(observer);

  var historyHashes = 0;
  final key = _Key(() => historyHashes++);
  final work = _Work();
  final map = _CountingMap({key: _Value(work)}, work);
  historyHashes = 0;
  map['added'] = _Value(work);
  final updateHistoryHashes = historyHashes;
  map.dispose();

  stdout.writeln(
    jsonEncode({
      'hasListener': dev.extensionStreamHasListener,
      'valueReads': work.valueReads,
      'historyReads': work.historyReads,
      'updateHistoryHashes': updateHistoryHashes,
      'serializations': work.serializations,
      'observerEvents': observer.events,
    }),
  );
}

class _Work {
  int valueReads = 0;
  int historyReads = 0;
  int serializations = 0;
}

class _CountingMap extends MapSignal<Object, _Value> {
  _CountingMap(super.initialValue, this.work) : super(trackPreviousValue: true);

  final _Work work;

  @override
  Map<Object, _Value> get value {
    work.valueReads++;
    return super.value;
  }

  @override
  Map<Object, _Value>? get previousValue {
    work.historyReads++;
    return super.previousValue;
  }
}

class _Value {
  _Value(this.work);

  final _Work work;

  int toJson() => ++work.serializations;
}

@immutable
class _Key {
  const _Key(this.onHash);

  final void Function() onHash;

  @override
  int get hashCode {
    onHash();
    return identityHashCode(this);
  }

  @override
  bool operator ==(Object other) => identical(this, other);
}

class _Observer extends SolidartObserver {
  final events = <String>[];

  @override
  void didCreateSignal(SignalBase<Object?> signal) => events.add('created');

  @override
  void didUpdateSignal(SignalBase<Object?> signal) => events.add('updated');

  @override
  void didDisposeSignal(SignalBase<Object?> signal) => events.add('disposed');
}
