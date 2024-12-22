import 'package:alien_signals/alien_signals.dart' as alien;

// ignore: public_member_api_docs
abstract interface class EffectScope {
  factory EffectScope() = _EffectScope;

  // ignore: public_member_api_docs
  T run<T>(T Function() fn);

  // ignore: public_member_api_docs
  void stop();
}

final class _EffectScope extends alien.EffectScope implements EffectScope {}
