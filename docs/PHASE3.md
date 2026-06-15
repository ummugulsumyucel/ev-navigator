# EV Navigator — Faz 3

## Firebase Proje Bilgileri

| Alan | Değer |
|------|-------|
| **Project ID** | `ev-navigator-tr` |
| **Display Name** | EV Navigator TR |
| **Storage Bucket** | `ev-navigator-tr.appspot.com` |
| **iOS Bundle ID** | `com.evnavigator.app` |

### Firebase Console'da Proje Oluşturma

1. [Firebase Console](https://console.firebase.google.com) → **Proje Ekle**
2. Proje adı: **EV Navigator TR**
3. Project ID: **ev-navigator-tr** (benzersiz olmalı — doluysa `ev-navigator-tr-xxx` kullanın ve `firebase_config.dart` güncelleyin)
4. Google Analytics: İsteğe bağlı

```bash
firebase login
flutterfire configure --project=ev-navigator-tr
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Faz 3 Modülleri

| Modül | Route | Açıklama |
|-------|-------|----------|
| Araç Yönetimi | `/vehicles`, `/vehicles/add` | CRUD, birincil araç, Firestore `vehicles` |
| Bildirimler | `/notifications` | FCM + Firestore `notifications` |
| Offline Cache | — | Hive ile istasyon cache |
| Admin RBAC | `admin/` | Firestore `role=admin` kontrolü |

## FCM Kurulumu

- Arka plan handler: `lib/core/services/fcm_service.dart`
- Token kaydı: giriş sonrası `users.fcmToken`
- Bildirim türleri: `station_outage`, `charge_complete`, `new_comment`, `new_follower`, `news`, `appointment`

## Admin Kullanıcı Oluşturma

Firebase Console → Firestore → `users/{uid}`:

```json
{
  "role": "admin"
}
```

## Örnek Araç Verisi

```json
{
  "ownerId": "USER_UID",
  "brand": "Tesla",
  "model": "Model Y",
  "year": 2024,
  "batteryKwh": 75,
  "wltpRangeKm": 533,
  "plate": "34 ABC 123",
  "isPrimary": true,
  "createdAt": "<timestamp>"
}
```

## Örnek Bildirim

```json
{
  "userId": "USER_UID",
  "type": "charge_complete",
  "title": "Şarj Tamamlandı",
  "body": "ZES Maslak istasyonunda şarjınız %100'e ulaştı.",
  "read": false,
  "data": { "stationId": "xxx" },
  "createdAt": "<timestamp>"
}
```
