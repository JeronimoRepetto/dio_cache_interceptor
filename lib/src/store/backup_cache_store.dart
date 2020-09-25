import 'package:meta/meta.dart';

import '../model/cache_priority.dart';
import '../model/cache_response.dart';
import 'cache_store.dart';

/// A store that save each request result in a dedicated [primary]
/// store and [secondary] store.
///
/// Cached responses are read from [primary] first, and then
/// from [secondary].
///
/// Note: [secondary] is not awaited on writing operations
/// (including set / clean / delete).
///
/// Mostly useful when you want MemCacheStore before another.
///
class BackupCacheStore extends CacheStore {
  /// Primary cache store
  final CacheStore primary;

  /// Secondary cache store
  final CacheStore secondary;

  BackupCacheStore({@required this.primary, @required this.secondary})
      : assert(primary != null),
        assert(secondary != null);

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool stalledOnly = false,
  }) async {
    secondary.clean(
      priorityOrBelow: priorityOrBelow,
      stalledOnly: stalledOnly,
    );
    await primary.clean(
      priorityOrBelow: priorityOrBelow,
      stalledOnly: stalledOnly,
    );
  }

  @override
  Future<void> delete(String key, {bool stalledOnly = false}) async {
    secondary.delete(key, stalledOnly: stalledOnly);
    await primary.delete(key, stalledOnly: stalledOnly);
  }

  @override
  Future<bool> exists(String key) async {
    return await primary.exists(key) || await secondary.exists(key);
  }

  @override
  Future<CacheResponse> get(String key) async {
    final resp = await primary.get(key);
    if (resp != null) return resp;

    return await secondary.get(key);
  }

  @override
  Future<void> set(CacheResponse response) async {
    secondary.set(response);
    await primary.set(response);
  }
}
