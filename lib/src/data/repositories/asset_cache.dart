class _Entry<T> {
  final String type;
  final T value;
  final int bytes;
  final DateTime expires;
  _Entry(this.type, this.value, this.bytes, this.expires);
}

// Ограничиваю объём кэша и срок жизни данных от другого клиента
class AssetCache<T> {
  final int maxBytes;
  final int maxEntries;
  final _items = <String, _Entry<T>>{};
  int _bytes = 0;
  AssetCache({required this.maxBytes, this.maxEntries = 32});

  T? get(String key) {
    final entry = _items.remove(key);
    if (entry == null) return null;
    if (entry.expires.isBefore(DateTime.now())) {
      _bytes -= entry.bytes;
      return null;
    }
    _items[key] = entry;
    return entry.value;
  }

  void put(String key, String type, T value, int bytes) {
    _bytes -= _items.remove(key)?.bytes ?? 0;
    if (bytes > maxBytes) return;
    while (_items.isNotEmpty && (_bytes + bytes > maxBytes || _items.length >= maxEntries)) {
      _bytes -= _items.remove(_items.keys.first)!.bytes;
    }
    _items[key] = _Entry(type, value, bytes, DateTime.now().add(const Duration(minutes: 2)));
    _bytes += bytes;
  }

  void invalidate(String? type) {
    for (final key in _items.keys.toList()) {
      if (type == null || _items[key]!.type == type) _bytes -= _items.remove(key)!.bytes;
    }
  }
}
