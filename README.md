<div align="center">

<img src="assets/images/logo.png" alt="EV Navigator Logo" width="120" height="120" />

# ⚡ EV Navigator

**Türkiye'nin Elektrikli Araç Süper Uygulaması**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)](https://flutter.dev/multi-platform)

[Özellikler](#-özellikler) • [Ekran Görüntüleri](#-ekran-görüntüleri) • [Kurulum](#-kurulum) • [Mimari](#-mimari) • [Katkı](#-katkı)

</div>

---

## 📱 Proje Hakkında

EV Navigator, Türkiye'deki elektrikli araç sürücüleri için tasarlanmış kapsamlı bir mobil uygulamadır. Şarj istasyonu haritası, güzergah planlayıcı, batarya sağlığı takibi, maliyet hesaplayıcı ve topluluk platformunu tek çatı altında bir araya getirir.

> **MVP Durumu:** Tüm temel özellikler tamamlanmış, production'a hazır.

---

## ✨ Özellikler

### 🗺️ Şarj İstasyonu Haritası
- Gerçek zamanlı Firestore stream ile canlı istasyon durumu
- ZES, Eşarj, Trugo, WAT, Tesla, Shell Recharge ağları
- Soket tipi (CCS2, CHAdeMO, AC Type 2, Tesla), ağ, fiyat ve müsaitlik filtresi
- Dark tema uyumlu Google Maps entegrasyonu
- İstasyon detayı: soket listesi, fiyat, güvenilirlik puanı, yorumlar, favori ekleme

### 🔋 Batarya Sağlığı
- SOH (State of Health), SOC, sıcaklık ve şarj döngüsü takibi
- Günlük / haftalık / aylık grafik görünümü (fl_chart)
- Gerçek menzil ve tüketim analizi

### 🛣️ Güzergah Planlayıcı
- Şehir ismi ile geocoding (geocoding paketi)
- Araç modeline göre şarj durağı hesaplama (Haversine algoritması)
- 4 strateji: En Hızlı, En Ucuz, Dengeli, En Güvenli
- Rota geçmişi (Firestore'da kalıcı)

### 💰 Maliyet Hesaplayıcı
- EV vs Benzin vs Dizel aylık / yıllık karşılaştırması
- AC / DC şarj tipi etkisi
- Güncel Türkiye yakıt fiyatları ile hesaplama

### 🔧 Servis & Destek
- Yakın EV servislerini harita üzerinde göster
- Randevu talebi, telefon ile arama, yol tarifi

### 💬 Topluluk
- Marka bazlı gönderi akışı (Togg, Tesla, BMW, Hyundai, MG…)
- Beğeni, yorum, sonsuz kaydırma (infinite scroll)
- Firestore boşken örnek gönderiler ile dolu görünen arayüz

### 🔔 Bildirimler
- Firebase Cloud Messaging (FCM) entegrasyonu
- Uygulama içi bildirim merkezi, okundu işaretleme

### 👤 Kullanıcı & Araç Yönetimi
- E-posta / Google / Apple ile kimlik doğrulama
- Birden fazla araç, birincil araç seçimi
- Favori istasyonlar, profil düzenleme

---

## 📸 Ekran Görüntüleri

| Ana Sayfa | Şarj Haritası | Güzergah |
|:---------:|:-------------:|:--------:|
| ![home](docs/screenshots/home.png) | ![map](docs/screenshots/map.png) | ![planner](docs/screenshots/planner.png) |

| Batarya | Maliyet | Topluluk |
|:-------:|:-------:|:--------:|
| ![battery](docs/screenshots/battery.png) | ![cost](docs/screenshots/cost.png) | ![community](docs/screenshots/community.png) |

---

## 🏗️ Mimari

Clean Architecture + Riverpod + Firebase kombinasyonu:

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── config/          # AppConfig, AppBootstrap, FirebaseConfig
│   ├── network/         # Dio client, Directions API
│   ├── router/          # GoRouter — tüm rotalar & redirect mantığı
│   ├── services/        # Firebase, FCM, Hive, SecureStorage providers
│   ├── theme/           # Dark tema — AppColors, AppSpacing, AppRadius
│   ├── utils/           # Result<T>, Validators, AuthErrorFormatter
│   └── widgets/         # AppCard, StatCard, MainShell, LoadingWidgets
└── features/
    ├── auth/            # Email · Google · Apple Sign-In
    ├── home/            # Dashboard — istatistik + yakın istasyonlar
    ├── map/             # Harita + istasyon detayı + filtreler
    ├── trip_planner/    # Güzergah planlayıcı
    ├── battery/         # Batarya sağlığı grafikleri
    ├── cost/            # Maliyet hesaplayıcı
    ├── service/         # EV servis haritası
    ├── community/       # Topluluk gönderileri
    ├── notifications/   # FCM + uygulama içi bildirimler
    ├── vehicles/        # Araç yönetimi
    └── profile/         # Kullanıcı profili
```

Her `feature` katmanı:
```
feature/
├── data/
│   ├── models/          # Firestore ↔ Dart DTO'ları
│   └── repositories/    # Repository implementasyonları
├── domain/
│   ├── entities/        # Saf Dart entity sınıfları
│   └── repositories/    # Soyut interface'ler
└── presentation/
    ├── providers/        # Riverpod state notifiers
    └── screens/          # Flutter widget'ları
```

---

## 🛠️ Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| **UI Framework** | Flutter 3.x |
| **State Management** | Riverpod 2.x |
| **Navigasyon** | GoRouter 14.x |
| **Backend** | Firebase (Auth · Firestore · Storage · FCM) |
| **Harita** | Google Maps Flutter |
| **HTTP** | Dio 5.x |
| **Offline Cache** | Hive Flutter |
| **Güvenli Depolama** | flutter_secure_storage |
| **Grafikler** | fl_chart |
| **Görsel Cache** | cached_network_image |
| **Konum** | geolocator |
| **Geocoding** | geocoding |
| **Kimlik Doğrulama** | google_sign_in · sign_in_with_apple |

---


## 🔥 Firestore Koleksiyonları

| Koleksiyon | Açıklama |
|------------|----------|
| `users` | Kullanıcı profilleri, istatistikler, FCM token |
| `charging_stations` | Şarj istasyonu verileri |
| `station_reviews` | İstasyon yorumları |
| `favorites` | Kullanıcı favori istasyonları |
| `community_posts` | Topluluk gönderileri |
| `comments` | Gönderi yorumları |
| `battery_reports` | Batarya sağlığı kayıtları |
| `trips` | Kayıtlı güzergahlar |
| `notifications` | Kullanıcı bildirimleri |
| `services` | EV servis merkezleri |
| `news` | Uygulama içi haberler |



---

<div align="center">

**⚡ EV Navigator** — Elektrikli geleceğe şarj dolu adımlarla

</div>
