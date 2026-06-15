# Görevler: Akıllı Şarj Haritası

## Uygulama Görevi Listesi

- [x] 1 Veri katmanı ve modelleri oluştur
  - [x] 1.1 `ChargingStation`, `ChargingSocket`, `StationFilters`, `ReliabilityScore`, `ReservationRequest`, `ReservationResult`, `UserStationReport`, `PriceOption` veri modellerini `lib/models/` altında tanımla
  - [x] 1.2 `NetworkType`, `SocketType`, `StationStatus`, `SocketStatus`, `UserReportType`, `ReservationErrorType` enum'larını oluştur
  - [x] 1.3 `LocalCacheService` sınıfını oluştur: istasyon listesi (5 dk TTL) ve doluluk durumu (30 sn TTL) için bellek tabanlı önbellek
  - [ ] 1.4 `ChargingStationRepository` soyut sınıfını ve `ChargingStationRepositoryImpl` somut uygulamasını oluştur

- [x] 2 Ağ adaptörleri oluştur
  - [x] 2.1 `ChargingNetworkAdapter` soyut sınıfını `lib/services/network_adapters/` altında tanımla
  - [x] 2.2 `ZesNetworkAdapter`'ı oluştur: `fetchStations`, `fetchStatus`, `reserve` metodlarıyla (mock veri ile)
  - [x] 2.3 `EsarjNetworkAdapter`'ı oluştur
  - [x] 2.4 `TrugoNetworkAdapter`'ı oluştur
  - [x] 2.5 `WatNetworkAdapter`'ı oluştur
  - [x] 2.6 `TeslaNetworkAdapter`'ı oluştur
  - [x] 2.7 `ShellRechargeNetworkAdapter`'ı oluştur
  - [x] 2.8 `NetworkAggregatorService`'i oluştur: tüm adaptörleri paralel olarak `Future.wait()` ile çalıştırır, hata yönetimi ve normalizasyon dahil

- [x] 3 Gerçek zamanlı durum servisleri oluştur
  - [ ] 3.1 `RealtimeStatusService`'i oluştur: `web_socket_channel` ile WebSocket bağlantısı, fallback olarak 30 sn polling
  - [x] 3.2 `UserReportService`'i oluştur: rapor gönderme, alma ve 24 saatlik spam önleme kontrolü
  - [x] 3.3 Kullanıcı raporları ile API verisinin uzlaştırma mantığını `SmartChargingMapProvider`'a ekle

- [x] 4 Güvenilirlik puanı motorunu oluştur
  - [ ] 4.1 `OutageHistoryRepository`'yi oluştur: son 90 gün bozulma geçmişini depolar ve sorgular
  - [x] 4.2 `ReliabilityScoreEngine`'i oluştur: ağırlıklı skor hesaplama (%40 bozulma, %35 inceleme, %25 anlık durum)
  - [ ] 4.3 Güvenilirlik skoru için birim testleri yaz: sıfır bozulma, aşırı bozulma, karışık inceleme senaryoları

- [x] 5 Rezervasyon ve bildirim servislerini oluştur
  - [x] 5.1 `ReservationService`'i oluştur: `isReservationSupported` kontrolü, `reserve`, `cancelReservation`, `getUserReservations`
  - [ ] 5.2 `NotificationService`'i oluştur: `flutter_local_notifications` ve `firebase_messaging` entegrasyonu; istasyon aboneliği ve rezervasyon hatırlatması
  - [ ] 5.3 Rezervasyondan 15 dakika önce yerel bildirim programlama mantığını ekle

- [x] 6 Fiyat karşılaştırma servisini oluştur
  - [x] 6.1 Fiyat karşılaştırma: güzergah bazlı maliyet hesaplama (`SmartChargingMapProvider.getRouteBasedPrices`) uygulama içine entegre edildi
  - [ ] 6.2 Fiyat verisi için 1 saatlik önbellek stratejisini ayrı servis olarak uygula
  - [x] 6.3 Fiyat sıralama ve "En iyi fiyat" işaretleme mantığını ekle

- [x] 7 `SmartChargingMapProvider`'ı oluştur
  - [x] 7.1 `ChangeNotifier` tabanlı `SmartChargingMapProvider`'ı `lib/providers/` altında oluştur
  - [x] 7.2 `initialize`, `loadStationsInBounds` (500 ms debounce), `applyFilters` metodlarını uygula
  - [x] 7.3 `selectStation`, `clearSelection`, `refreshStationStatus` metodlarını uygula
  - [x] 7.4 `makeReservation`, `getRouteBasedPrices`, `submitUserReport`, `toggleNotificationSubscription` metodlarını uygula
  - [x] 7.5 `main.dart`'ta `MultiProvider`'a `SmartChargingMapProvider`'ı kaydet

- [x] 8 Harita UI bileşenlerini oluştur
  - [ ] 8.1 `google_maps_flutter` bağımlılığını `pubspec.yaml`'a ekle; Android ve iOS platform ayarlarını yapılandır (API key)
  - [ ] 8.2 Mevcut placeholder harita konteynerini gerçek `GoogleMap` widget'ıyla değiştir
  - [x] 8.3 Ağa özgü renk/ikon ile `_StationMarker` widget'ını oluştur
  - [x] 8.4 Harita işaretçilerinde müsait soket sayısını gösteren rozeti uygula
  - [x] 8.5 Güvenilirlik puanı 2.5 altındaki işaretçilere uyarı ikonu ekle

- [x] 9 Filtre UI bileşenlerini oluştur
  - [x] 9.1 `FilterBottomSheet` widget'ını oluştur: ağ, soket tipi, minimum güç, maksimum fiyat, minimum güvenilirlik, yalnızca müsait, yalnızca rezervasyonlu
  - [x] 9.2 Aktif filtreleri harita üzerinde her zaman görünür chip bandı olarak göster
  - [ ] 9.3 Filtre tercihlerini `shared_preferences` ile kalıcı hale getir

- [x] 10 İstasyon detay bottom sheet'ini oluştur
  - [x] 10.1 `StationDetailBottomSheet` adlı ayrı bir widget oluşturuldu
  - [x] 10.2 Güvenilirlik puanı bileşen dökümü (bozulma/inceleme/durum) eklendi
  - [x] 10.3 Rezervasyon UI'ı eklendi: tarih/saat seçici, süre seçici, onay/iptal akışı
  - [x] 10.4 Kullanıcı raporu gönderme UI'ı eklendi (çalışıyor/arızalı/kapalı/fiyat yanlış)
  - [x] 10.5 Bildirim aboneliği butonu eklendi (abone ol / aboneliği kaldır)

- [x] 11 Fiyat karşılaştırma UI bileşenini oluştur
  - [x] 11.1 `_PriceComparisonSheet` widget'ı oluşturuldu: tahmini maliyete göre sıralı liste
  - [x] 11.2 "En iyi fiyat" rozeti harita ve liste görünümüne eklendi
  - [x] 11.3 Fiyat bilinmeyen istasyonlar için "Bilinmiyor" etiketi uygulandı

- [x] 12 Bildirim ve çevrimdışı UI entegrasyonunu tamamla
  - [x] 12.1 "Çevrimdışı — önbellek verisi gösteriliyor" bilgi bandı `MapScreen`'e eklendi
  - [x] 12.2 Kısmi ağ hatası durumunda "X ağından veri alınamadı" uyarı kartı uygulandı
  - [ ] 12.3 Uygulama arkaplandayken gelen arıza bildirimlerini işleme mantığını uygula (firebase_messaging entegrasyonu bekliyor)

- [ ] 13 Entegrasyon testleri ve son düzenlemeler
  - [ ] 13.1 Mock HTTP sunucusu ile her ağ adaptörü için veri dönüşümü entegrasyon testleri yaz
  - [ ] 13.2 `SmartChargingMapProvider` → `LocalCacheService` tam akışını test et
  - [ ] 13.3 Filtre tutarlılığı özellik testini yaz
  - [ ] 13.4 Tüm gereksinimlere karşı manuel kabul testi yapıldığını doğrula ve eksik işlevselliği tamamla
