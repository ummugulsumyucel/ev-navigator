# EV Navigator — Faz 2

## Yeni Modüller

| Modül | Route | Firestore |
|-------|-------|-----------|
| Güzergah Planlayıcı | `/planner` | `trips` |
| Batarya Sağlığı | `/battery` | `battery_reports` |
| Maliyet Hesaplayıcı | `/cost` | — (yerel hesaplama) |
| Servis & Destek | `/service` | `services`, `appointments` |
| Topluluk | `/community` | `community_posts`, `comments` |

## Navigasyon

Alt menü: Ana Sayfa · Harita · Plan · Topluluk · Profil

Batarya, Maliyet ve Servis: Dashboard hızlı erişim + Profil menüsünden.

## Gerekli API Anahtarları

```bash
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=... \
  --dart-define=GOOGLE_DIRECTIONS_API_KEY=... \
  --dart-define=FIREBASE_API_KEY=... \
  ...
```

## Örnek Firestore Verileri

### battery_reports
```json
{
  "userId": "UID",
  "vehicleId": "tesla_model_y",
  "soh": 94.5,
  "soc": 78,
  "temperatureC": 28.5,
  "chargeCycles": 142,
  "realRangeKm": 410,
  "efficiencyKwhPer100km": 17.2,
  "recordedAt": "<timestamp>"
}
```

### services
```json
{
  "name": "Tesla Yetkili Servis Maslak",
  "brand": "Tesla",
  "type": "authorized",
  "location": { "lat": 41.108, "lng": 29.021 },
  "address": "Maslak, İstanbul",
  "phone": "+902121234567",
  "rating": 4.7,
  "reviewCount": 89,
  "serviceTypes": ["Periyodik Bakım", "Yazılım Güncelleme"],
  "avgWaitDays": 3
}
```

### community_posts
```json
{
  "authorId": "UID",
  "authorName": "Ahmet Y.",
  "brand": "Tesla",
  "title": "Uzun yol deneyimim",
  "content": "Ankara-İstanbul arası tek şarj yetti...",
  "photoUrls": [],
  "likeCount": 0,
  "commentCount": 0,
  "likedBy": [],
  "createdAt": "<timestamp>"
}
```

## Firestore İndeksleri

`firebase deploy --only firestore:indexes` ile güncel indeksleri deploy edin.
