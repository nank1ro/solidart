import 'package:alien_signals/alien_signals.dart';
import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
T untrack<T>(ReadableSignal<T> signal) {
  final prevActiveTrackId = activeTrackId;
  final prevActiveScopeTrackId = activeScopeTrackId;

  activeTrackId = activeScopeTrackId = 0;
  try {
    return signal.value;
  } finally {
    activeTrackId = prevActiveTrackId;
    activeScopeTrackId = prevActiveScopeTrackId;
  }
}
