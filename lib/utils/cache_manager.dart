class CacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamp = {};

  static T? get<T>(String key, Duration maxAge) {
    final timestamp = _cacheTimestamp[key];
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age < maxAge) {
        return _cache[key] as T?;
      }
    }
    return null;
  }

  static void set<T>(String key, T value) {
    _cache[key] = value;
    _cacheTimestamp[key] = DateTime.now();
  }

  static void clear(String? prefix) {
    if (prefix == null) {
      _cache.clear();
      _cacheTimestamp.clear();
    } else {
      final keysToRemove =
          _cache.keys.where((key) => key.startsWith(prefix)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _cacheTimestamp.remove(key);
      }
    }
  }
}
