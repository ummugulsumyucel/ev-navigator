import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/firebase_config.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await FirebaseConfig.initialize();

    final hive = HiveCacheService();
    await hive.init();

    await FcmService.initialize(
      onForegroundMessage: (message) {
        debugPrint('Bildirim: ${message.notification?.title}');
      },
    );
  }
}

/// FCM token'ı kullanıcı giriş yaptığında kaydet
final fcmTokenSyncProvider = Provider<void>((ref) {
  ref.listen(authStateStreamProvider, (_, next) async {
    final user = next.valueOrNull;
    if (user != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(authRepositoryProvider).updateFcmToken(token);
      }
    }
  });
});
