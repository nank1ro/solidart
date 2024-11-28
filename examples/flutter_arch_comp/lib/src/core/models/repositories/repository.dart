/// Repository represents a repository for type [T]. Each repository supports
/// one-shot CRUD operations on the data [T], and methods be notified of data
/// changes over time. For more information see
/// https://developer.android.com/jetpack/guide/data-layer
abstract class Repository<T> {
  /// Watches this repository for changes in the data specified by the given
  /// id, if any. Changes are triggered by actions like create, update, delete,
  /// and refresh
  Stream<T?> watch(int id);

  /// Watches this repository for changes in the list of data. Changes are
  /// triggered by actions like create, update, delete, and refresh
  Stream<List<T>> watchAll();

  /// Creates the given data into this repository. It throws an [Exception]
  /// in case of any error
  Future<void> create(T data);

  /// Returns the data specified by the given id if any, null otherwise. It
  /// throws an [Exception] in case of any error
  Future<T?> read(int id);

  /// Returns all the data if any, an empty list otherwise. It throws an
  /// [Exception] in case of any error
  Future<List<T>> readAll();

  /// Updates the given data into this repository. It throws an [Exception]
  /// in case of any error
  Future<void> update(T data);

  /// Deletes the data specified by the given id if any. It throws an
  /// [Exception] in case of any error
  Future<void> delete(int id);

  /// Refreshes the actual data with the most up to date data. It throws an
  /// [Exception] in case of any error
  Future<void> refresh();

  /// Disposes this repository
  void dispose();
}
