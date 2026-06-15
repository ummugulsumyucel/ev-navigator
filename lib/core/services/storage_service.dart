import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}

class HiveCacheService {
  static const String stationsBox = 'stations_cache';
  static const String userBox = 'user_cache';
  static const String stationDetailBox = 'station_detail_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(stationsBox);
    await Hive.openBox<Map>(userBox);
    await Hive.openBox<Map>(stationDetailBox);
  }

  Future<void> cacheStations(String key, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(stationsBox);
    await box.put(key, data);
  }

  Map<String, dynamic>? getCachedStations(String key) {
    final box = Hive.box<Map>(stationsBox);
    final data = box.get(key);
    return data?.cast<String, dynamic>();
  }

  Future<void> cacheStationDetail(String id, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(stationDetailBox);
    await box.put(id, data);
  }

  Map<String, dynamic>? getCachedStationDetail(String id) {
    final box = Hive.box<Map>(stationDetailBox);
    final data = box.get(id);
    return data?.cast<String, dynamic>();
  }

  Future<void> cacheUserProfile(String uid, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(userBox);
    await box.put(uid, data);
  }

  Map<String, dynamic>? getCachedUserProfile(String uid) {
    final box = Hive.box<Map>(userBox);
    final data = box.get(uid);
    return data?.cast<String, dynamic>();
  }

  Future<void> clearAll() async {
    await Hive.box<Map>(stationsBox).clear();
    await Hive.box<Map>(userBox).clear();
    await Hive.box<Map>(stationDetailBox).clear();
  }
}
