# EV Navigator — Faz 1 MVP

## Kapsam

| Modül | Durum |
|-------|-------|
| Authentication (Email, Google, Apple) | ✅ |
| Dashboard (istatistikler + yakın istasyonlar) | ✅ |
| Şarj Haritası (Google Maps + Firestore) | ✅ |
| Kullanıcı Profili (düzenleme + favoriler) | ✅ |
| Firebase altyapısı (Auth, Firestore, FCM, Rules) | ✅ |

Faz 2'de eklenecek: Güzergah planlayıcı, batarya, maliyet, servis, topluluk.

## Klasör Yapısı

```
lib/
├── main.dart
├── core/
│   ├── config/          # Firebase, bootstrap, app config
│   ├── router/          # GoRouter (MVP rotaları)
│   ├── services/        # Firebase + Hive providers
│   ├── theme/           # Dark tema (#00D26A)
│   ├── utils/           # Validators, Result
│   └── widgets/         # AppCard, MainShell, Loading
└── features/
    ├── auth/            # Clean Architecture
    ├── home/            # Dashboard
    ├── map/             # Harita + istasyon detay
    └── profile/         # Profil + düzenleme
```

## Firestore Koleksiyonları (MVP)

- `users` — kullanıcı profilleri
- `charging_stations` — şarj istasyonları
- `station_reviews` — istasyon yorumları
- `favorites` — kullanıcı favorileri

## Kurulum

```bash
# 1. Bağımlılıklar
flutter pub get

# 2. Firebase
flutterfire configure

# 3. Çalıştır
flutter run -d windows \
  --dart-define=GOOGLE_MAPS_API_KEY=AIza... \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=ev-navigator-tr \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...

# 4. Security rules
firebase deploy --only firestore:rules,firestore:indexes
```

## Örnek İstasyon Verisi

Admin panel veya Firebase Console üzerinden `charging_stations` koleksiyonuna:

```json
{
  "name": "ZES Maslak",
  "network": "zes",
  "location": { "lat": 41.1086, "lng": 29.0214 },
  "address": "Maslak Mah. Büyükdere Cad.",
  "city": "İstanbul",
  "sockets": [
    { "id": "1", "type": "ccs2", "powerKw": 180, "status": "available" }
  ],
  "status": "available",
  "reliabilityScore": 4.5,
  "supportsReservation": true,
  "photoUrls": [],
  "availableCount": 2,
  "totalSockets": 4,
  "pricePerKwh": 12.50,
  "updatedAt": "<server timestamp>"
}
```

## Ekran Akışı

```
Splash → Login/Register
  → Email Verification (email kayıt)
  → Profile Completion
  → Dashboard (Home)
       ↔ Map ↔ Profile
       → Station Detail
       → Edit Profile
```
