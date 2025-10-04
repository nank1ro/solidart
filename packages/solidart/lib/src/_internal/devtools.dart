// coverage:ignore-start

// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:solidart/src/computed.dart';
import 'package:solidart/src/config.dart';
import 'package:solidart/src/signal.dart';

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
extension DevToolsExt<T> on ReadonlySignal<T> {
  void notifySignalCreation() {
    for (final obs in SolidartConfig.observers) {
      obs.didCreateSignal(this);
    }
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.created);
  }

  void notifySignalUpdate() {
    for (final obs in SolidartConfig.observers) {
      obs.didUpdateSignal(this);
    }
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.updated);
  }

  void notifySignalDisposal() {
    for (final obs in SolidartConfig.observers) {
      obs.didDisposeSignal(this);
    }
    if (!trackInDevTools) return;
    _notifyDevToolsAboutSignal(this, eventType: DevToolsEventType.disposed);
  }
}

void _notifyDevToolsAboutSignal(
  ReadonlySignal<dynamic> signal, {
  required DevToolsEventType eventType,
}) {
  if (!SolidartConfig.devToolsEnabled || !signal.trackInDevTools) return;
  final eventName = 'ext.solidart.signal.${eventType.name}';
  var value = signal.value;
  var previousValue = signal.previousValue;
  // if (signal is Resource) {
  //   value = signal._value.asReady?.value;
  //   previousValue = signal._previousValue?.asReady?.value;
  // }
  final jsonValue = _toJson(value);
  final jsonPreviousValue = _toJson(previousValue);

  dev.postEvent(eventName, {
    'name': signal.name,
    'value': jsonValue,
    'previousValue': jsonPreviousValue,
    'hasPreviousValue': signal.hasPreviousValue,
    'type': switch (signal) {
      // Resource() => 'Resource',
      // ListSignal() => 'ListSignal',
      // MapSignal() => 'MapSignal',
      // SetSignal() => 'SetSignal',
      Signal() => 'Signal',
      Computed() => 'Computed',
      ReadonlySignal() => 'ReadSignal',
      // _ => 'Unknown',
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
