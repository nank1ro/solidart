// ignore_for_file: public_member_api_docs

mixin Disposable {
  late final _callbacks = <void Function()>[];

  bool _isDisposed = false;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  bool get isDisposed => _isDisposed;

  bool get autoDispose;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void onDispose(void Function() callback) {
    if (isDisposed) return;
    _callbacks.add(callback);
  }

  void dispose() {
    if (isDisposed) return;

    _isDisposed = true;
    for (final callback in _callbacks) {
      callback();
    }

    _callbacks.clear();
  }

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  void maybeDispose() {
    if (autoDispose) dispose();
  }
}
