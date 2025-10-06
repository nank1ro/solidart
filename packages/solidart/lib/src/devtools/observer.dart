import 'node.dart';

abstract interface class SolidartObserver {
  const SolidartObserver();

  void onCreated(Node node);
  void onUpdated(Node node);
  void onDisposed(Node node);
}
