import 'dart:developer' as developer;

import 'node.dart';
import 'observer.dart';

final class DevToolsObserver implements SolidartObserver {
  const DevToolsObserver();

  @override
  void onCreated(Node node) {
    developer.postEvent('ext.solidart.created', node.toJson());
  }

  @override
  void onDisposed(Node node) {
    developer.postEvent('ext.solidart.disposed', node.toJson());
  }

  @override
  void onUpdated(Node node) {
    developer.postEvent('ext.solidart.updated', node.toJson());
  }
}
