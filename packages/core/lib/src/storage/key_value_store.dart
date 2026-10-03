import 'package:hive_ce_flutter/hive_flutter.dart';

/// Small persistent key-value store for flags and settings
/// (e.g. "onboarding seen"). Features depend on this interface, not on Hive.
abstract interface class KeyValueStore {
  T? read<T>(String key);

  Future<void> write<T>(String key, T value);

  Future<void> delete(String key);
}

/// [KeyValueStore] backed by a hive_ce box.
class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore(this._box);

  final Box<dynamic> _box;

  /// Initializes Hive in the app documents directory and opens [boxName].
  static Future<HiveKeyValueStore> open({
    String boxName = 'app_settings',
  }) async {
    await Hive.initFlutter();
    return HiveKeyValueStore(await Hive.openBox<dynamic>(boxName));
  }

  @override
  T? read<T>(String key) => _box.get(key) as T?;

  @override
  Future<void> write<T>(String key, T value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);
}
