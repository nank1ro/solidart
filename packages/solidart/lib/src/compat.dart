import 'package:solidart/src/signal.dart';

// ignore: public_member_api_docs
extension CallOperatorSignal<T> on ReadableSignal<T> {
  // ignore: public_member_api_docs
  T call() => value;
}

// ignore: public_member_api_docs
extension SignalSttter<T> on Signal<T> {
  // ignore: public_member_api_docs, use_setters_to_change_properties
  void set(T value) => this.value = value;
}

// ignore: public_member_api_docs
extension ToggleSignal on Signal<bool> {
  // ignore: public_member_api_docs
  void toggle() => value = !value;
}
