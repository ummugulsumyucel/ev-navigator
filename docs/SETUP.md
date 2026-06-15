# EV Navigator — Kurulum Rehberi

## 1. Firebase Kurulumu

> **Proje:** [ev-navigator-tr](https://console.firebase.google.com/project/ev-navigator-tr)  
> Proje farklı bir Google hesabındaysa önce o hesapla giriş yapın.

### Hızlı kurulum (Windows)

```powershell
.\scripts\setup-firebase-ev-navigator.ps1
```

### Manuel adımlar

```bash
# 1. Yanlış hesaptan çık, ev-navigator-tr hesabıyla gir
firebase logout
firebase login

# 2. FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure --project=ev-navigator-tr --platforms=web,android
```

### Firebase Console'da kontrol edin

1. [Authentication → Sign-in method](https://console.firebase.google.com/project/ev-navigator-tr/authentication/providers) → **E-posta/Parola** etkin
2. [Firestore Database](https://console.firebase.google.com/project/ev-navigator-tr/firestore) oluşturulmuş olmalı
3. Kuralları deploy edin:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

`lib/firebase_options.dart` dosyası `flutterfire configure` ile otomatik oluşur.  
`lib/core/config/firebase_config.dart` bu dosyayı kullanır — elle düzenlemenize gerek yok.

### Eski / yanlış hesap sorunu

Terminalde `firebase projects:list` çalıştırın. Listede `ev-navigator-tr` görünmüyorsa yanlış Google hesabındasınız:

```bash
firebase logout
firebase login   # ev-navigator-tr projesinin sahibi olan hesap
firebase projects:list   # ev-navigator-tr listede olmalı
flutterfire configure --project=ev-navigator-tr
```

## 2. API Anahtarları (Harita)

```bash
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=AIza... \
  --dart-define=GOOGLE_DIRECTIONS_API_KEY=AIza...
```

> Firebase anahtarları `lib/firebase_options.dart` içinde — `--dart-define=FIREBASE_*` gerekmez.

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_KEY"/>
```

### iOS — `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_KEY")
```

## 3. Firestore Rules Deploy

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 4. Admin Panel

```bash
cd admin
flutter run -d chrome
```

## 5. Klasör Yapısı

```
lib/
├── core/           # Tema, router, network, utils
├── features/       # Clean Architecture modülleri
│   ├── auth/
│   ├── home/
│   ├── map/
│   ├── trip_planner/
│   ├── battery/
│   ├── cost/
│   ├── service/
│   ├── community/
│   └── profile/
└── main.dart
admin/              # Flutter Web admin panel
docs/               # Mimari dokümantasyon
```

## 6. App Store / Play Store

- [ ] `flutter create .` ile iOS klasörü oluştur
- [ ] Privacy Policy URL
- [ ] App icons (1024x1024)
- [ ] Screenshots
- [ ] Apple Sign In capability (iOS)
- [ ] Google Sign In SHA-1 fingerprint (Android)
