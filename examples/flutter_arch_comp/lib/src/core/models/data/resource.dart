/// Lifecycle of a resource:
/// Resource.loading() retrieving started
/// Resource.loading(localData) retrieving continues, local data
/// Resource.success(remoteData) retrieving successful, remote data
/// Resource.error('msg') retrieving unsuccessful, no data
/// Resource.error('msg', localData) retrieving successful, local data
///
/// Inspired by https://github.com/android/architecture-components-samples/blob/88747993139224a4bb6dbe985adf652d557de621/GithubBrowserSample/app/src/main/java/com/android/example/github/vo/Resource.kt
class Resource<T> {
  /// Use static methods to initialize this class
  Resource(this.status, {this.data, this.msg = ''});

  final Status status;
  final T? data;
  final String msg;

  static Resource<T> loading<T>({T? data}) =>
      Resource(Status.loading, data: data);

  static Resource<T> success<T>(T data) => Resource(Status.success, data: data);

  static Resource<T> error<T>(String msg, {T? data}) =>
      Resource(Status.error, data: data, msg: msg);
}

// TODO(alesalv): rename this to ResourceStatus
// Status represents one of [loading, success, error]
enum Status {
  loading,
  success,
  error,
}
