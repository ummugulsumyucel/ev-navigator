import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Arka plan FCM handler — main.dart'ta kayıt edilir.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM arka plan: ${message.notification?.title}');
}

class FcmService {
  FcmService._();

  static Future<void> initialize({
    void Function(RemoteMessage)? onForegroundMessage,
    void Function(RemoteMessage)? onMessageOpenedApp,
  }) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM ön plan: ${message.notification?.title}');
      onForegroundMessage?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM tıklandı: ${message.notification?.title}');
      onMessageOpenedApp?.call(message);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      onMessageOpenedApp?.call(initial);
    }
  }
}
