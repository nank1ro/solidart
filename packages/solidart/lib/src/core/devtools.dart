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

// Event construction can run user code while reading values and metadata.
// Keep direct reads from disposing dependency-free computeds.
var _devToolsEventDepth = 0;

bool get _isBuildingDevToolsEvent => _devToolsEventDepth > 0;

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
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
  }

  void _notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    if (!SolidartConfig.devToolsEnabled) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
  }

  // Each observer and the DevTools event is its own step of [errors], so a
  // throwing observer does not skip the others.
  void _notifySignalDisposal(_FirstError errors) {
    for (final obs in SolidartConfig.observers) {
      errors.run(() => obs.didDisposeSignal(this));
    }
    if (!SolidartConfig.devToolsEnabled) return;
    errors.run(
      () => _notifyDevToolsAboutSignal(
        this,
        eventType: DevToolsEventType.disposed,
      ),
    );
  }
}

void _notifyDevToolsAboutSignal(
  SignalBase<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled) return;
  // Keep event reads out of the active effect or computed.
  _devToolsEventDepth++;
  try {
    untracked(() {
      if (signal.trackInDevTools) {
        _postSignalEvent(signal, eventType: eventType);
      }
    });
  } finally {
    _devToolsEventDepth--;
  }
}

void _postSignalEvent(
  SignalBase<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  final eventName = 'ext.solidart.signal.${eventType.name}';
  Object? value;
  Object? previousValue;
  if (signal is Resource) {
    value = signal._untrackedValue.asReady?.value;
    previousValue = signal._previousValue?.asReady?.value;
  } else if (signal is Computed) {
    if (signal._initialized) {
      value = signal._untrackedValue;
      previousValue = signal._previousValue;
    }
  } else if (signal.untrackedHasValue) {
    value = signal.value;
    previousValue = signal.previousValue;
  }
  final hasPreviousValue = signal.untrackedHasPreviousValue;
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
