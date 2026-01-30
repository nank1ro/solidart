part of '../solidart.dart';

// coverage:ignore-start
Object? _computedValue<T>(Computed<T> signal) {
  final current = signal.currentValue;
  if (current != null || null is T) {
    return current;
  }
  return null;
}
// coverage:ignore-end

// coverage:ignore-start
bool _hasPreviousValue(ReadonlySignal<Object?> signal) {
  if (!signal.trackPreviousValue) return false;
  if (signal is Signal) {
    return signal._previousValue is Some;
  }
  if (signal is Computed) {
    return signal._previousValue is Some;
  }
  return false;
}
// coverage:ignore-end

// coverage:ignore-start
int _listenerCount(system.ReactiveNode node) {
  var count = 0;
  var link = node.subs;
  while (link != null) {
    count++;
    link = link.nextSub;
  }
  return count;
}
// coverage:ignore-end

void _notifyDevToolsAboutSignal(
  ReadonlySignal<Object?> signal, {
  required _DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  final eventName = 'ext.solidart.signal.${eventType.name}';
  final value = _signalValue(signal);
  final previousValue = _signalPreviousValue(signal);
  final hasPreviousValue = _hasPreviousValue(signal);

  dev.postEvent(eventName, {
    '_id': signal.identifier.value.toString(),
    'name': signal.identifier.name,
    'value': _toJson(value),
    'previousValue': _toJson(previousValue),
    'hasPreviousValue': hasPreviousValue,
    'type': _signalType(signal),
    'valueType': value.runtimeType.toString(),
    if (hasPreviousValue)
      'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal.isDisposed,
    'autoDispose': signal.autoDispose,
    'listenerCount': _listenerCount(signal),
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}

void _notifySignalCreation(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didCreateSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.created);
}

void _notifySignalDisposal(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didDisposeSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.disposed);
}

void _notifySignalUpdate(ReadonlySignal<Object?> signal) {
  if (signal.trackInDevTools && SolidartConfig.observers.isNotEmpty) {
    for (final observer in SolidartConfig.observers) {
      observer.didUpdateSignal(signal);
    }
  }
  _notifyDevToolsAboutSignal(signal, eventType: _DevToolsEventType.updated);
}

Object? _resourceValue(ResourceState<dynamic>? state) {
  if (state == null) return null;
  return state.maybeWhen(orElse: () => null, ready: (value) => value);
}

Object? _signalPreviousValue(ReadonlySignal<Object?> signal) {
  if (signal is Resource) {
    return _resourceValue(signal.untrackedPreviousState);
  }
  return signal.untrackedPreviousValue;
}

String _signalType(ReadonlySignal<Object?> signal) => switch (signal) {
  Resource() => 'Resource',
  ListSignal() => 'ListSignal',
  MapSignal() => 'MapSignal',
  SetSignal() => 'SetSignal',
  LazySignal() => 'LazySignal',
  Signal() => 'Signal',
  Computed() => 'Computed',
  _ => 'ReadonlySignal',
};

Object? _signalValue(ReadonlySignal<Object?> signal) {
  if (signal is Resource) {
    return _resourceValue(signal.untrackedState);
  }
  if (signal is LazySignal && !signal.isInitialized) {
    return null;
  }
  if (signal is Computed) {
    return _computedValue(signal);
  }
  return signal.untrackedValue;
}

// coverage:ignore-start
dynamic _toJson(Object? obj, [int depth = 0, Set<Object>? visited]) {
  const maxDepth = 20;
  if (depth > maxDepth) return '<max depth exceeded>';
  try {
    return jsonEncode(obj);
  } catch (_) {
    if (obj is List) {
      final visitedSet = visited ?? Set<Object>.identity();
      if (!visitedSet.add(obj)) return '<circular>';
      try {
        return obj
            .map((e) => _toJson(e, depth + 1, visitedSet))
            .toList()
            .toString();
      } finally {
        visitedSet.remove(obj);
      }
    }
    if (obj is Set) {
      final visitedSet = visited ?? Set<Object>.identity();
      if (!visitedSet.add(obj)) return '<circular>';
      try {
        return obj
            .map((e) => _toJson(e, depth + 1, visitedSet))
            .toList()
            .toString();
      } finally {
        visitedSet.remove(obj);
      }
    }
    if (obj is Map) {
      final visitedSet = visited ?? Set<Object>.identity();
      if (!visitedSet.add(obj)) return '<circular>';
      try {
        return obj
            .map(
              (key, value) => MapEntry(
                _toJson(key, depth + 1, visitedSet),
                _toJson(value, depth + 1, visitedSet),
              ),
            )
            .toString();
      } finally {
        visitedSet.remove(obj);
      }
    }
    return jsonEncode(obj.toString());
  }
}

enum _DevToolsEventType {
  created,
  updated,
  disposed,
}
