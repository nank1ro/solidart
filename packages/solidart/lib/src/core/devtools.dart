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

  // Each observer and the DevTools event is its own step of [errors], so a
  // throwing observer does not skip the others.
  void _notifySignalUpdate(_FirstError errors) {
    final observers = SolidartConfig.observers;
    if (observers.isNotEmpty) {
      // Registration changes apply to later updates.
      for (final obs in observers.toList(growable: false)) {
        errors.run(() => obs.didUpdateSignal(this));
      }
    }
    if (!SolidartConfig.devToolsEnabled) return;
    errors.run(
      () => _notifyDevToolsAboutSignal(
        this,
        eventType: DevToolsEventType.updated,
      ),
    );
  }

  // Like [_notifySignalUpdate].
  void _notifySignalDisposal(_FirstError errors) {
    for (final obs in SolidartConfig.observers) {
      errors.run(() => obs.didDisposeSignal(this));
    }
    if (!trackInDevTools) return;
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
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  // Peek: inspecting must not track, resolve a lazy signal, or auto-dispose.
  untracked(() => _postSignalEvent(signal, eventType: eventType));
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
