part of 'core.dart';

/// coverage:ignore-start

/// The type of the event emitted to the devtools
enum DevToolsEventType {
  /// The signal was created
  created,

  /// The signal was updated
  updated,

  /// The signal was disposed
  disposed,
}

dynamic _toJson(Object? obj) {
  try {
    return jsonEncode(obj);
  } catch (e) {
    if (obj is List) {
      return obj.map(_toJson).toList().toString();
    }
    if (obj is Set) {
      return obj.map(_toJson).toList().toString();
    }
    if (obj is Map) {
      return obj
          .map((key, value) => MapEntry(_toJson(key), _toJson(value)))
          .toString();
    }
    return jsonEncode(obj.toString());
  }
}

/// Extension for the devtools
extension DevToolsExt<T> on SignalBase<T> {
  void _notifySignalCreation() {
    for (final obs in SolidartConfig.observers) {
      obs.didCreateSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
    // coverage:ignore-end
  }

  void _notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
    // coverage:ignore-end
  }

  void _notifySignalDisposal() {
    for (final obs in SolidartConfig.observers) {
      obs.didDisposeSignal(this);
    }
    // coverage:ignore-start
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.disposed);
    // coverage:ignore-end
  }
}

void _notifyDevToolsAboutSignal(
  SignalBase<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  final eventName = 'solidart.signal.${eventType.name}';
  var value = signal.value;
  var previousValue = signal.previousValue;
  if (signal is Resource) {
    value = signal._value.asReady?.value;
    previousValue = signal._previousValue?.asReady?.value;
  }
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    'name': signal.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'hasPreviousValue': signal.hasPreviousValue,
    'type': switch (signal) {
      Resource() => 'Resource',
      ListSignal() => 'ListSignal',
      MapSignal() => 'MapSignal',
      SetSignal() => 'SetSignal',
      Signal() => 'Signal',
      Computed() => 'Computed',
      ReadableSignal() => 'ReadSignal',
      _ => 'Unknown',
    },
    'valueType': value.runtimeType.toString(),
    if (signal.hasPreviousValue)
      'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal.disposed,
    'autoDispose': signal.autoDispose,
    'listenerCount': signal.listenerCount,
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}
// coverage:ignore-end
