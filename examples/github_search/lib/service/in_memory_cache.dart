import 'package:meta/meta.dart';

/// Provides an inmemory cache used to avoid repeating an async callback within a
/// certain [duration]
@immutable
class InMemoryCache<T> {
  InMemoryCache(this.duration);

  final Duration duration;
  final Map<Object, _CacheEntry<T>?> _cache = {};

  void _cacheValue(T value, Object key) {
    _cache[key] = _CacheEntry(
      timestamp: DateTime.now(),
      data: value,
    );
  }

  /// Returns a cached value from a previous call to [fetch], or runs [callback]
  /// to compute a new one.
  ///
  /// If [fetch] has been called recently enough, returns its previous return
  /// value. Otherwise, runs [callback] and returns its new return value.
  Future<T> fetch(
    Future<T> Function() callback, {
    String? key,
  }) async {
    final effectiveKey = key ?? callback;
    final entry = _cache[effectiveKey];

    Future<T> fetchAndCache() async {
      final value = await callback();
      _cacheValue(value, effectiveKey);
      return value;
    }

    if (entry == null) {
      return fetchAndCache();
    } else {
      final now = DateTime.now();
      final difference = now.difference(entry.timestamp);
      if (difference > duration) {
        return fetchAndCache();
      }
    }

    return entry.data;
  }
}

class _CacheEntry<T> {
  _CacheEntry({
    required this.timestamp,
    required this.data,
  });

  final DateTime timestamp;
  final T data;
}
