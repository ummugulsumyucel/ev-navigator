import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Firebase yapılandırması — Proje: ev-navigator-tr
/// https://console.firebase.google.com/project/ev-navigator-tr
class FirebaseConfig {
  static const String projectId = 'ev-navigator-tr';
  static const String projectDisplayName = 'EV Navigator TR';
  static const String storageBucket = 'ev-navigator-tr.appspot.com';

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    final options = DefaultFirebaseOptions.currentPlatform;

    if (options.projectId != projectId) {
      throw FirebaseException(
        plugin: 'core',
        message:
            'Firebase yanlış projeye bağlı (${options.projectId}). '
            'ev-navigator-tr hesabıyla: firebase logout → firebase login → '
            'flutterfire configure --project=ev-navigator-tr',
      );
    }

    await Firebase.initializeApp(options: options);

    if (kDebugMode) {
      debugPrint('✅ Firebase bağlandı: $projectId');
    }
  }

  static bool get isConfigured {
    try {
      return DefaultFirebaseOptions.currentPlatform.projectId == projectId;
    } catch (_) {
      return false;
    }
  }
}
