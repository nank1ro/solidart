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

String _toJson(Object? obj) {
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
      final entries = <String>[];
      final keys = <String>{};
      var canEncodeAsObject = true;
      for (final entry in obj.entries) {
        final key = _toJson(entry.key);
        canEncodeAsObject =
            canEncodeAsObject && key.startsWith('"') && keys.add(key);
        entries.add('$key: ${_toJson(entry.value)}');
      }
      final rendered = '{${entries.join(', ')}}';
      // JSON objects need unique string keys. Keep every entry in the display
      // text when the rendered keys cannot form an object.
      return canEncodeAsObject ? rendered : jsonEncode(rendered);
    }
    return jsonEncode(obj.toString());
  }
}

// jsonEncode accepts distinct String keys with equal text in an identity map.
// Quote the affected objects before the extension decodes the JSON and loses
// entries. Scan the encoded text so user serialization callbacks run as usual.
String _preserveDuplicateJsonKeys(String json) {
  if (!json.contains('{')) return json;

  final objects = <_JsonObjectKeys>[];
  final collisions = <({int start, int end})>[];
  for (var i = 0; i < json.length; i++) {
    switch (json[i]) {
      case '{':
        objects.add(_JsonObjectKeys(i, collisions.length));
      case '}':
        final object = objects.removeLast();
        if (object.hasDuplicateKey) {
          // The display text already includes any nested duplicate entries.
          collisions
            ..length = object.firstNestedCollision
            ..add((start: object.start, end: i + 1));
        }
      case '"':
        final start = i++;
        while (json[i] != '"') {
          i += json[i] == r'\' ? 2 : 1;
        }
        // Both JSON writers put the colon immediately after a key.
        if (i + 1 < json.length && json[i + 1] == ':') {
          final object = objects.last;
          if (!object.hasDuplicateKey) {
            object.hasDuplicateKey = !object.keys.add(
              json.substring(start, i + 1),
            );
          }
        }
    }
  }

  if (collisions.isEmpty) return json;
  final result = StringBuffer();
  var offset = 0;
  for (final (:start, :end) in collisions) {
    result
      ..write(json.substring(offset, start))
      ..write(jsonEncode(json.substring(start, end)));
    offset = end;
  }
  result.write(json.substring(offset));
  return result.toString();
}

class _JsonObjectKeys {
  _JsonObjectKeys(this.start, this.firstNestedCollision);

  final int start;
  final int firstNestedCollision;
  final keys = <String>{};
  bool hasDuplicateKey = false;
}

/// Extension for the devtools
extension DevToolsExt<T> on SignalBase<T> {
  void _notifySignalCreation() {
    for (final obs in SolidartConfig.observers) {
      obs.didCreateSignal(this);
    }
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
  if (!SolidartConfig.devToolsEnabled || !dev.extensionStreamHasListener) {
    return;
  }
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
  final jsonValue = _preserveDuplicateJsonKeys(_toJson(value));
  final jsonPreviousValue = _preserveDuplicateJsonKeys(_toJson(previousValue));

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
