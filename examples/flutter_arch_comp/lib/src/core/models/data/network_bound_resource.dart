import 'package:flutter_arch_comp/src/core/models/data/resource.dart';

abstract class NetworkBoundResource<T> {
  Future<Resource<T>> loadFromDb();

  Future<void> persistToDb(T data);

  Future<Resource<T>> loadFromServer();

  bool shouldFetch(Resource<T> resource);

  void setValue(Resource<T> resource);

  Future<void> retrieveAll() async {
    /// loading
    setValue(Resource.loading());
    final localResource = await loadFromDb();

    /// local resource is either 'success' or 'error'
    /// fetches from network in case local is outdated, or 'error'
    if (shouldFetch(localResource)) {
      _fetchFromNetwork(localResource);
    } else {
      /// success
      setValue(Resource.success(localResource.data as T));
    }
  }

  Future<void> _fetchFromNetwork(Resource<T> localResource) async {
    if (Status.success == localResource.status) {
      /// loading with data
      setValue(Resource.loading(data: localResource.data));
    }

    final remoteResource = await loadFromServer();

    if (Status.success == remoteResource.status) {
      await persistToDb(remoteResource.data as T);
      final persisted = await loadFromDb();

      /// success
      setValue(Resource.success(persisted.data as T));
    } else {
      /// error
      setValue(Resource.error(remoteResource.msg,
          data: remoteResource.data ?? localResource.data));
    }
  }
}
