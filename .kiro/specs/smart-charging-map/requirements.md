# Gereksinimler: Akıllı Şarj Haritası

## Gereksinim 1: Çok Ağlı İstasyon Görüntüleme

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, tüm Türkiye şarj ağlarını (ZES, Eşarj, Trugo, WAT, Tesla, Shell Recharge) tek bir haritada görmek istiyorum; böylece farklı uygulamalar arasında geçiş yapmadan en yakın ve uygun istasyonu bulurum.

### Kabul Kriterleri

- [ ] 1.1 Harita açıldığında görünür alanda tüm etkin şarj ağlarına ait istasyonlar görüntülenmelidir.
- [ ] 1.2 Her ağ, kendine özgü renk veya ikon ile ayrıştırılmalıdır (ZES, Eşarj, Trugo, WAT, Tesla, Shell Recharge).
- [ ] 1.3 Harita kaydırıldığında veya yakınlaştırıldığında yeni görünür alandaki istasyonlar 2 saniye içinde yüklenmelidir.
- [ ] 1.4 API'den veri alınamazsa, önbellekteki (en fazla 5 dakika eski) veriler gösterilmeli ve kullanıcıya önbellek verisi kullandığı bildirilmelidir.
- [ ] 1.5 200'den fazla işaretçi gösterilmesi gerektiğinde, işaretçiler otomatik olarak kümelenmelidir.
- [ ] 1.6 Bir ağın API'si yanıt vermediğinde, diğer ağların verileri bozulmadan gösterilmeye devam etmeli ve başarısız ağlar için uyarı gösterilmelidir.

---

## Gereksinim 2: Gerçek Zamanlı Doluluk Durumu

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, bir istasyona gitmeden önce kaç soketin müsait olduğunu gerçek zamanlı olarak görmek istiyorum; boş yere gitmekten kaçınırım.

### Kabul Kriterleri

- [ ] 2.1 Her istasyon işaretçisinde müsait/dolu/arızalı soket sayısı görüntülenmelidir.
- [ ] 2.2 Doluluk durumu, WebSocket bağlantısı destekleyen ağlarda anlık olarak güncellenmelidir; WebSocket desteklemeyen ağlarda en fazla 30 saniyede bir polling yapılmalıdır.
- [ ] 2.3 Kullanıcılar, bir istasyonun mevcut durumunu manuel olarak raporlayabilmelidir (çalışıyor, arızalı, kapalı, fiyat yanlış).
- [ ] 2.4 Son 10 dakika içinde gelen kullanıcı raporu, API verisinden farklıysa, "Kullanıcı tarafından güncellendi" etiketi ile öne alınmalıdır.
- [ ] 2.5 Çevrimdışı durumda harita son bilinen doluluk verisini göstermeli ve "Çevrimdışı" bandı görüntülenmelidir.

---

## Gereksinim 3: İstasyon Güvenilirlik Puanı

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, bir istasyonun geçmiş performansını gösteren güvenilirlik puanını görmek istiyorum; böylece sık arızalanan istasyonlara gitmekten kaçınırım.

### Kabul Kriterleri

- [ ] 3.1 Her istasyona, 0.0–5.0 arası güvenilirlik puanı hesaplanmalıdır.
- [ ] 3.2 Güvenilirlik puanı şu üç bileşenden oluşmalıdır: bozulma geçmişi (son 90 gün, %40 ağırlık), kullanıcı yorumları (%35 ağırlık), anlık durum (%25 ağırlık).
- [ ] 3.3 İstasyon detay ekranında puan bileşenleri ayrı ayrı gösterilmelidir.
- [ ] 3.4 Puan 2.5'in altına düşen istasyonlarda harita işaretçisinde uyarı ikonu görünmelidir.
- [ ] 3.5 Yeni veya veri yetersiz istasyonlar için puan göstergesi "Veri yok" olarak işaretlenmelidir.

---

## Gereksinim 4: Soket Tipi Filtreleme

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, haritayı aracımın desteklediği soket tiplerine (CCS2, CHAdeMO, AC Type 2, Tesla) göre filtrelemek istiyorum; uyumsuz istasyonlara gitmem gerekmez.

### Kabul Kriterleri

- [ ] 4.1 Harita ekranında soket tipi filtre seçenekleri sunulmalıdır: CCS2, CHAdeMO, AC Type 2, Tesla.
- [ ] 4.2 Filtre seçildiğinde, seçili soket tipine sahip olmayan istasyonlar haritadan kaldırılmalıdır.
- [ ] 4.3 Birden fazla soket tipi aynı anda seçilebilmeli ve haritada bu tiplerden en az birine sahip istasyonlar gösterilmelidir.
- [ ] 4.4 Minimum güç (kW) filtresi uygulanabilmelidir; seçilen değerin altında kalan soketler filtrelenerek çıkarılmalıdır.
- [ ] 4.5 Yalnızca müsait soket filtresi aktif edildiğinde, tüm soketleri dolu olan istasyonlar haritada gösterilmemelidir.
- [ ] 4.6 Filtre tercihleri oturum kapatılıp açıldıktan sonra da korunmalıdır.
- [ ] 4.7 Aktif filtreler harita üzerindeki bir bant/chip alanında her zaman görünür olmalıdır.

---

## Gereksinim 5: Şarj Yuvası Rezervasyonu

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, istasyona varmadan önce soket rezervasyonu yapmak istiyorum; ağ API'si desteklediği sürece meşgul bir istasyona gidip beklemem gerekmez.

### Kabul Kriterleri

- [ ] 5.1 Rezervasyon destekleyen ağlara ait istasyonlarda "Rezervasyon Yap" butonu görünmelidir; desteklemeyen ağlarda bu buton gösterilmemelidir.
- [ ] 5.2 Kullanıcı, başlangıç saatini ve süreyi seçerek rezervasyon talebi yapabilmelidir.
- [ ] 5.3 Rezervasyon onaylandığında, kullanıcıya rezervasyon kimliği ve onaylanan saat gösterilmelidir.
- [ ] 5.4 Slot meşgul ise kullanıcıya açıklayıcı mesajla hata gösterilmeli ve alternatif saatler önerilmelidir.
- [ ] 5.5 Mevcut rezervasyonlar iptal edilebilmelidir.
- [ ] 5.6 Rezervasyon başlangıcından 15 dakika önce yerel bildirim gönderilmelidir.

---

## Gereksinim 6: Kapalı / Arızalı İstasyon Bildirimleri

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, favori istasyonlarımdan biri kapandığında veya arızalandığında hemen haberdar olmak istiyorum; planımı güzergaha çıkmadan önce değiştirebilirim.

### Kabul Kriterleri

- [ ] 6.1 Kullanıcılar istedikleri istasyonlara bildirim aboneliği yapabilmelidir.
- [ ] 6.2 Abone olunan bir istasyon kapanır veya arızalanırsa, 5 dakika içinde push bildirimi gönderilmelidir.
- [ ] 6.3 Bildirimde istasyon adı, ağ ve tahmini etki süresi (varsa) yer almalıdır.
- [ ] 6.4 İstasyon tekrar müsait hale geldiğinde de bildirim gönderilmelidir.
- [ ] 6.5 Bildirim tercihlerini yönetmek için ayar sayfasına ulaşan bağlantı sunulmalıdır.

---

## Gereksinim 7: Güzergah Bazlı Fiyat Karşılaştırması

### Kullanıcı Hikayesi

Bir EV kullanıcısı olarak, güzergahım üzerindeki istasyonların fiyatlarını karşılaştırmak ve en ucuz seçeneği görmek istiyorum; böylece şarj maliyetimi optimize ederim.

### Kabul Kriterleri

- [ ] 7.1 Aktif bir güzergah varken, güzergah üzerindeki istasyonların kWh fiyatları karşılaştırmalı olarak listelenmelidir.
- [ ] 7.2 Liste, tahmini toplam şarj maliyetine (güzergah sapma maliyeti dahil) göre en ucuzdan en pahalıya sıralanmalıdır.
- [ ] 7.3 Aracın verimliliği (kWh/100km) hesaba katılarak tahmini toplam maliyet Türk Lirası cinsinden gösterilmelidir.
- [ ] 7.4 Fiyat bilgisi olmayan istasyonlar listede "Fiyat bilinmiyor" etiketiyle gösterilmelidir.
- [ ] 7.5 En ucuz seçenek, harita üzerinde özel bir "En iyi fiyat" rozeti ile işaretlenmelidir.
- [ ] 7.6 Fiyat verileri en fazla 1 saatte bir güncellenmelidir.
