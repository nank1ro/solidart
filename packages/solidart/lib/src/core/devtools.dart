part of 'core.dart';

// coverage:ignore-start

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
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
  }

  void _notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
  }

  void _notifySignalDisposal() {
    for (final obs in SolidartConfig.observers) {
      obs.didDisposeSignal(this);
    }
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.disposed);
  }
}

void _notifyDevToolsAboutSignal(
  SignalBase<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  // Inspecting a signal for DevTools must not change the app's behavior.
  // Reading a Computed's value runs the auto-dispose check, which would dispose
  // a freshly created, dependency-free Computed the moment DevTools reads it
  // (see issue #185). Suppress auto-dispose for the duration of the read.
  final computed = signal is Computed ? signal : null;
  computed?._devToolsReading = true;
  try {
    _emitDevToolsEvent(signal, eventType: eventType);
  } finally {
    computed?._devToolsReading = false;
  }
}

void _emitDevToolsEvent(
  SignalBase<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  final eventName = 'ext.solidart.signal.${eventType.name}';
  final hasValue = signal.untrackedHasValue;
  var value = hasValue ? signal.value : null;
  var previousValue = hasValue ? signal.previousValue : null;
  final hasPreviousValue = signal.untrackedHasPreviousValue;
  if (signal is Resource) {
    value = signal._value.asReady?.value;
    previousValue = signal._previousValue?.asReady?.value;
  }
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    '_id': signal._id,
    'name': signal.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'hasPreviousValue': hasPreviousValue,
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
    if (hasPreviousValue)
      'previousValueType': previousValue.runtimeType.toString(),
    'disposed': signal.disposed,
    'autoDispose': signal.autoDispose,
    'listenerCount': signal.listenerCount,
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}

// coverage:ignore-end
