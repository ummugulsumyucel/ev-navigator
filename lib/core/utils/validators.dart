class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'E-posta gerekli';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Geçerli bir e-posta girin';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 8) return 'Şifre en az 8 karakter olmalı';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'En az bir büyük harf içermeli';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'En az bir rakam içermeli';
    }
    return null;
  }

  static String? required(String? value, {String field = 'Alan'}) {
    if (value == null || value.trim().isEmpty) return '$field gerekli';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 10) return 'Geçerli bir telefon numarası girin';
    return null;
  }
}
