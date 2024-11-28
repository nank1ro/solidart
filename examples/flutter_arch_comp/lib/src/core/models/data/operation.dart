/// Lifecycle of an operation:
/// Operation.loading() retrieving started
/// Operation.loading(localData) retrieving continues, local data
/// Operation.success(remoteData) retrieving successful, remote data
/// Operation.error('msg') retrieving unsuccessful, no data
/// Operation.error('msg', localData) retrieving successful, local data
///
/// Inspired by https://github.com/android/architecture-components-samples/blob/88747993139224a4bb6dbe985adf652d557de621/GithubBrowserSample/app/src/main/java/com/android/example/github/vo/Resource.kt
class Operation<T> {
  /// Use static methods to initialize this class
  Operation(this.status, {this.data, this.msg = ''});

  final OperationStatus status;
  final T? data;
  final String msg;

  bool get isLoading => status == OperationStatus.loading;
  bool get isSuccess => status == OperationStatus.success;
  bool get isError => status == OperationStatus.error;

  // TODO(alesalv): no need to pass data during loading
  static Operation<T> loading<T>({T? data}) =>
      Operation(OperationStatus.loading, data: data);

  static Operation<T> success<T>(T data) =>
      Operation(OperationStatus.success, data: data);

  static Operation<T> error<T>(String msg, {T? data}) =>
      Operation(OperationStatus.error, data: data, msg: msg);
}

// TODO(alesalv): make OperationStatus private

// OperationStatus represents one of [loading, success, error]
enum OperationStatus {
  loading,
  success,
  error,
}
