part of 'core.dart';

// coverage:ignore-start
bool get _devtoolsEnabled {
  var debugMode = false;
  assert(
    () {
      debugMode = true;
      return true;
    }(),
    '',
  );
  return debugMode;
}

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
  if (!_devtoolsEnabled) return;
  final eventName = 'solidart.signal.${eventType.name}';
  var value = signal._value;
  var previousValue = signal._previousValue;
  if (signal is Resource) {
    value = signal._value.asReady?.value;
    previousValue = signal._previousValue?.asReady?.value;
  }
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    'name': signal.options.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'hasPreviousValue': signal._hasPreviousValue,
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
    if (signal._hasPreviousValue)
      'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal._disposed,
    'autoDispose': signal.options.autoDispose,
    'listenerCount': signal.listenerCount,
  });
}
// coverage:ignore-end
