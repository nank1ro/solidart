import 'dart:convert';
import 'dart:developer' as dev;

import 'package:solidart/src/api_untrack.dart';
import 'package:solidart/src/computed.dart';
import 'package:solidart/src/namespace.dart';
import 'package:solidart/src/reactive/list.dart';
import 'package:solidart/src/reactive/map.dart';
import 'package:solidart/src/reactive/set.dart';
import 'package:solidart/src/signal.dart';

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

void notifyDevToolsAboutSignal(
  ReadableSignal<Object?> signal, {
  required DevToolsEventType eventType,
}) {
  if (!Solidart.dev) return;
  final eventName = 'solidart.signal.${eventType.name}';
  // ignore: prefer_final_locals
  final value = untrack(() => signal.value);
  // ignore: prefer_final_locals, avoid_init_to_null, prefer_const_declarations
  final previousValue = null; // TODO
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    'name': signal.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'hasPreviousValue': false, // TODO
    'type': switch (signal) {
      // Resource() => 'Resource',
      ListSignal() => 'ListSignal',
      MapSignal() => 'MapSignal',
      SetSignal() => 'SetSignal',
      Signal() => 'Signal',
      Computed() => 'Computed',
      ReadableSignal() => 'ReadSignal', // TODO: rename
    },
    'valueType': value.runtimeType.toString(),
    // if (signal._hasPreviousValue)
    //   'previousValueType': previousValue.runtimeType.toString(),
    'disposed': false,
    'autoDispose': false,
    'listenerCount': 0,
    'lastUpdate': DateTime.now().toIso8601String(),
  });
}
// coverage:ignore-end
