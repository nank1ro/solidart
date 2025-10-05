abstract interface class Disposable {
  bool get disposed;

  void dispose();
}

mixin AutoDisposable implements Disposable {
  bool get autoDispose;

  void maybeDispose() {
    if (autoDispose) dispose();
  }
}
