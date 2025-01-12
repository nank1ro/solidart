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

void _notifyDevToolsAboutSignal(
  ReadSignal<Object?> signal, {
  required DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  final eventName = 'solidart.signal.${eventType.name}';
  var value = signal._value;
  var previousValue = signal._previousValue;
  if (signal is Resource) {
    value = signal._value.asReady?.value;
    previousValue = signal._previousValue;
  }
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    'name': signal.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'type': switch (signal) {
      Resource() => 'Resource',
      ListSignal() => 'ListSignal',
      MapSignal() => 'MapSignal',
      SetSignal() => 'SetSignal',
      Signal() => 'Signal',
      Computed() => 'Computed',
      ReadSignal() => 'ReadSignal',
    },
    'valueType': value.runtimeType.toString(),
    'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal._disposed,
    'autoDispose': signal.autoDispose,
    'listenerCount': signal.listenerCount,
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}
// coverage:ignore-end
