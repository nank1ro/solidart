// ignore_for_file: public_member_api_docs

mixin Disposable {
  late final _callbacks = <void Function()>[];

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void onDispose(void Function() callback) {
    if (isDisposed) return;
    _callbacks.add(callback);
  }

  void dispose() {
    if (isDisposed) return;
    for (final callback in _callbacks) {
      callback();
    }

    _callbacks.clear();
    _isDisposed = true;
  }
}
