import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final hiveCacheProvider = Provider<HiveCacheService>((ref) {
  return HiveCacheService();
});
