import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.watch(firestoreProvider));
});

final servicesStreamProvider = StreamProvider<List<ServiceEntity>>((ref) {
  return ref
      .watch(serviceRepositoryProvider)
      .watchServices()
      .map((services) => services.isEmpty ? _mockServices : services);
});

final userAppointmentsProvider = StreamProvider<List<AppointmentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(serviceRepositoryProvider).watchUserAppointments(user.uid);
});

final serviceSearchProvider = StateProvider<String>((ref) => '');

final filteredServicesProvider =
    Provider<AsyncValue<List<ServiceEntity>>>((ref) {
  final servicesAsync = ref.watch(servicesStreamProvider);
  final query = ref.watch(serviceSearchProvider).toLowerCase();

  return servicesAsync.whenData((services) {
    if (query.isEmpty) return services;
    return services
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.brand.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query))
        .toList();
  });
});

// ---------------------------------------------------------------------------
// Statik demo servis verileri — Firestore boşken gösterilir
// ---------------------------------------------------------------------------

const List<ServiceEntity> _mockServices = [
  // ── YETKİLİ SERVİSLER ───────────────────────────────────────────────────
  ServiceEntity(
    id: 'svc_1',
    name: 'Tesla Service Center İstanbul',
    brand: 'Tesla',
    type: ServiceType.authorized,
    location: ServiceLocation(lat: 41.0620, lng: 29.0100),
    address: 'Bağcılar Mah. E-5 Yolu, Bağcılar / İstanbul',
    phone: '+902121234567',
    rating: 4.7,
    reviewCount: 312,
    serviceTypes: ['Yazılım Güncelleme', 'Batarya Bakım', 'Motor Servisi'],
    avgWaitDays: 3,
  ),
  ServiceEntity(
    id: 'svc_2',
    name: 'Togg Yetkili Servis Ankara',
    brand: 'Togg',
    type: ServiceType.authorized,
    location: ServiceLocation(lat: 39.9208, lng: 32.8541),
    address: 'Ostim OSB, Yenimahalle / Ankara',
    phone: '+903121234567',
    rating: 4.5,
    reviewCount: 148,
    serviceTypes: ['Periyodik Bakım', 'Şarj Sistemi', 'Fren Bakım'],
    avgWaitDays: 5,
  ),
  ServiceEntity(
    id: 'svc_3',
    name: 'BMW Yetkili Servis İzmir',
    brand: 'BMW',
    type: ServiceType.authorized,
    location: ServiceLocation(lat: 38.4189, lng: 27.1287),
    address: 'Alsancak Mah. Kıbrıs Şehitleri Cad., Konak / İzmir',
    phone: '+902321234567',
    rating: 4.8,
    reviewCount: 204,
    serviceTypes: ['iX / i4 Bakım', 'Batarya Tanı', 'Yazılım OTA'],
    avgWaitDays: 4,
  ),
  ServiceEntity(
    id: 'svc_4',
    name: 'Hyundai Yetkili Servis Bursa',
    brand: 'Hyundai',
    type: ServiceType.authorized,
    location: ServiceLocation(lat: 40.1885, lng: 29.0610),
    address: 'Organize San. Böl., Osmangazi / Bursa',
    phone: '+902241234567',
    rating: 4.4,
    reviewCount: 97,
    serviceTypes: ['IONIQ Bakım', 'Isı Yönetimi', 'Şarj Kablosu'],
    avgWaitDays: 6,
  ),
  ServiceEntity(
    id: 'svc_5',
    name: 'MG Yetkili Servis İstanbul Anadolu',
    brand: 'MG',
    type: ServiceType.authorized,
    location: ServiceLocation(lat: 40.9923, lng: 29.1244),
    address: 'Ataşehir Mah. İçerenköy Yolu, Ataşehir / İstanbul',
    phone: '+902161234567',
    rating: 4.3,
    reviewCount: 76,
    serviceTypes: ['MG4 Bakım', 'Batarya Kontrol', 'Klima Bakım'],
    avgWaitDays: 4,
  ),

  // ── ÖZEL / BAĞIMSIZ SERVİSLER ───────────────────────────────────────────
  ServiceEntity(
    id: 'svc_6',
    name: 'EV Teknik Elektrikli Araç Servisi',
    brand: 'Genel',
    type: ServiceType.independent,
    location: ServiceLocation(lat: 41.0450, lng: 28.8720),
    address: 'Güneşli Mah. TEM Yan Yol, Bağcılar / İstanbul',
    phone: '+905551234567',
    rating: 4.6,
    reviewCount: 183,
    serviceTypes: ['Tüm Markalar', 'Batarya Hücre Onarım', 'Yazılım Tanı'],
    avgWaitDays: 2,
  ),
  ServiceEntity(
    id: 'svc_7',
    name: 'Voltaj EV Workshop',
    brand: 'Genel',
    type: ServiceType.independent,
    location: ServiceLocation(lat: 39.9350, lng: 32.8200),
    address: 'Siteler Mah. Çiçek Sokak No:14, Altındağ / Ankara',
    phone: '+905421234567',
    rating: 4.4,
    reviewCount: 92,
    serviceTypes: ['DC Şarj Onarım', 'OBD Tanı', 'Akü Bakım'],
    avgWaitDays: 3,
  ),
  ServiceEntity(
    id: 'svc_8',
    name: 'GreenDrive Servis İzmir',
    brand: 'Genel',
    type: ServiceType.independent,
    location: ServiceLocation(lat: 38.4600, lng: 27.2100),
    address: 'Pınarbaşı Mah. Sanayi Cad. No:33, Bornova / İzmir',
    phone: '+905321234567',
    rating: 4.2,
    reviewCount: 55,
    serviceTypes: ['Şarj Sistemi', 'Fren Bakım', 'Araç Tanı'],
    avgWaitDays: 2,
  ),
];
