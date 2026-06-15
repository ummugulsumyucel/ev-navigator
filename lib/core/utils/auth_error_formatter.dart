import 'package:firebase_auth/firebase_auth.dart';

import 'result.dart';

/// Auth hatalarını kullanıcıya anlaşılır Türkçe metne çevirir.
String formatAuthError(Object? error) {
  if (error == null) {
    return 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
  }

  if (error is AuthFailure) {
    return _humanizeMessage(error.message);
  }

  if (error is FirebaseAuthException) {
    return _humanizeMessage(_mapFirebaseAuthCode(error));
  }

  final text = error.toString();
  if (text.contains('AuthFailure')) {
    final match = RegExp(r'AuthFailure:\s*(.+)').firstMatch(text);
    if (match != null) return _humanizeMessage(match.group(1)!);
  }

  return _humanizeMessage(text);
}

String _mapFirebaseAuthCode(FirebaseAuthException e) {
  return switch (e.code) {
    'user-not-found' => 'Bu e-posta ile kayıtlı hesap bulunamadı.',
    'wrong-password' => 'Hatalı şifre.',
    'invalid-credential' => 'E-posta veya şifre hatalı.',
    'email-already-in-use' => 'Bu e-posta zaten kullanımda. Giriş yapmayı deneyin.',
    'weak-password' => 'Şifre çok zayıf. En az 8 karakter kullanın.',
    'invalid-email' => 'Geçersiz e-posta adresi.',
    'too-many-requests' => 'Çok fazla deneme. Lütfen bir süre bekleyin.',
    'user-disabled' => 'Hesabınız devre dışı bırakılmış.',
    'network-request-failed' =>
      'İnternet bağlantısı yok veya sunucuya ulaşılamıyor.',
    'operation-not-allowed' =>
      'E-posta ile kayıt bu projede etkin değil. Firebase Console\'dan Email/Password\'ü açın.',
    'api-key-not-valid.-please-pass-a-valid-api-key' ||
    'invalid-api-key' =>
      'Firebase API anahtarı geçersiz. flutterfire configure ile projeyi bağlayın.',
    _ => e.message ?? 'Kimlik doğrulama hatası (${e.code}).',
  };
}

String _humanizeMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed == 'Error' || trimmed == 'error') {
    return 'Sunucuya bağlanılamadı. Firebase yapılandırması eksik olabilir — '
        'geliştirici flutterfire configure çalıştırmalı.';
  }
  if (trimmed.contains('YOUR_') && trimmed.contains('API_KEY')) {
    return 'Firebase henüz yapılandırılmamış. flutterfire configure çalıştırın.';
  }
  if (trimmed.contains('permission-denied') ||
      trimmed.contains('Missing or insufficient permissions')) {
    return 'Veritabanı izni reddedildi. Firestore kurallarını kontrol edin.';
  }
  if (trimmed.startsWith('Kayıt başarısız: Error') ||
      trimmed.startsWith('Kayıt başarısız: error')) {
    return 'Kayıt tamamlanamadı. Firebase bağlantısını kontrol edin.';
  }
  return trimmed;
}
