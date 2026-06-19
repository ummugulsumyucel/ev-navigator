import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/services/storage_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/station_repository_impl.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/repositories/station_repository.dart';

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepositoryImpl(
    ref.watch(firestoreProvider),
    cache: ref.watch(hiveCacheProvider),
  );
});

final userLocationProvider = FutureProvider<LatLng>((ref) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }
  // Konum izni yoksa İstanbul merkezi
  return const LatLng(41.0151, 28.9795);
});

// ---------------------------------------------------------------------------
// Map state
// ---------------------------------------------------------------------------

class MapBoundsState {
  const MapBoundsState({
    this.minLat = 36.0,
    this.maxLat = 42.5,
    this.minLng = 26.0,
    this.maxLng = 45.0,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  MapBoundsState copyWith({
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) =>
      MapBoundsState(
        minLat: minLat ?? this.minLat,
        maxLat: maxLat ?? this.maxLat,
        minLng: minLng ?? this.minLng,
        maxLng: maxLng ?? this.maxLng,
      );
}

class MapViewState {
  const MapViewState({
    this.bounds = const MapBoundsState(),
    this.filters = const StationFiltersEntity(),
    this.searchQuery = '',
  });

  final MapBoundsState bounds;
  final StationFiltersEntity filters;
  final String searchQuery;

  MapViewState copyWith({
    MapBoundsState? bounds,
    StationFiltersEntity? filters,
    String? searchQuery,
  }) =>
      MapViewState(
        bounds: bounds ?? this.bounds,
        filters: filters ?? this.filters,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class MapViewNotifier extends StateNotifier<MapViewState> {
  MapViewNotifier() : super(const MapViewState());

  void initFromLocation(double lat, double lng) {
    const delta = 0.25; // ~25 km
    state = state.copyWith(
      bounds: MapBoundsState(
        minLat: lat - delta,
        maxLat: lat + delta,
        minLng: lng - delta,
        maxLng: lng + delta,
      ),
    );
  }

  void updateBounds(LatLngBounds bounds) {
    state = state.copyWith(
      bounds: MapBoundsState(
        minLat: bounds.southwest.latitude,
        maxLat: bounds.northeast.latitude,
        minLng: bounds.southwest.longitude,
        maxLng: bounds.northeast.longitude,
      ),
    );
  }

  void applyFilters(StationFiltersEntity filters) =>
      state = state.copyWith(filters: filters);

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query.trim());
}

final mapViewNotifierProvider =
    StateNotifierProvider<MapViewNotifier, MapViewState>(
        (_) => MapViewNotifier());

// ---------------------------------------------------------------------------
// Stations providers  — mock'lar ANINDA emit edilir, Firestore arka planda
// ---------------------------------------------------------------------------

/// Mock'ları hemen yayınlar; Firestore'dan gerçek veri gelince onu kullanır.
Stream<List<ChargingStationEntity>> _mockFirst(
  Stream<List<ChargingStationEntity>> firestoreStream,
  List<ChargingStationEntity> fallback,
) async* {
  yield fallback; // ← loading spinner yok, anında göster
  await for (final list in firestoreStream) {
    yield list.isNotEmpty ? list : fallback;
  }
}

final stationsStreamProvider =
    StreamProvider.autoDispose<List<ChargingStationEntity>>((ref) {
  ref.keepAlive(); // provider dispose edilmesin, loading flash olmasın
  final viewState = ref.watch(mapViewNotifierProvider);
  final repo = ref.watch(stationRepositoryProvider);
  final query = viewState.searchQuery;

  if (query.isNotEmpty) {
    return _mockFirst(
      repo.watchAllStations(filters: viewState.filters),
      _mockStations,
    );
  }

  final minLat = viewState.bounds.minLat;
  final maxLat = viewState.bounds.maxLat;
  final minLng = viewState.bounds.minLng;
  final maxLng = viewState.bounds.maxLng;

  // Bounds içindeki mock'ları hazırla
  final localMock = _mockStations.where((s) {
    return s.location.lat >= minLat &&
        s.location.lat <= maxLat &&
        s.location.lng >= minLng &&
        s.location.lng <= maxLng;
  }).toList();

  return _mockFirst(
    repo.watchStations(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
      filters: viewState.filters,
    ),
    localMock.isNotEmpty ? localMock : _mockStations,
  );
});

final filteredStationsProvider =
    Provider.autoDispose<AsyncValue<List<ChargingStationEntity>>>((ref) {
  ref.keepAlive();
  final stationsAsync = ref.watch(stationsStreamProvider);
  final query = ref.watch(mapViewNotifierProvider).searchQuery.toLowerCase();

  // Stream geçici loading'e girerse önceki veriyi koru
  if (stationsAsync.isLoading) {
    final previous = stationsAsync.valueOrNull;
    if (previous != null) {
      return AsyncData(query.isEmpty
          ? previous
          : previous.where((s) {
              return s.name.toLowerCase().contains(query) ||
                  s.city.toLowerCase().contains(query) ||
                  s.network.displayName.toLowerCase().contains(query) ||
                  s.address.toLowerCase().contains(query);
            }).toList());
    }
  }

  return stationsAsync.whenData((stations) {
    if (query.isEmpty) return stations;
    return stations.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query) ||
          s.network.displayName.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();
  });
});

final nearbyStationsProvider =
    FutureProvider<List<ChargingStationEntity>>((ref) async {
  final location = await ref.watch(userLocationProvider.future);

  // Mock'lardan yakınları hesapla — hızlı sonuç
  final sorted = List<ChargingStationEntity>.from(_mockStations)
    ..sort((a, b) {
      double d(ChargingStationEntity s) {
        final dlat = s.location.lat - location.latitude;
        final dlng = s.location.lng - location.longitude;
        return dlat * dlat + dlng * dlng;
      }

      return d(a).compareTo(d(b));
    });
  final mockNearby = sorted.take(8).toList();

  try {
    final result = await ref
        .watch(stationRepositoryProvider)
        .getNearbyStations(lat: location.latitude, lng: location.longitude)
        .timeout(const Duration(seconds: 4));
    return result.isNotEmpty ? result : mockNearby;
  } catch (_) {
    return mockNearby;
  }
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, stationId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(stationRepositoryProvider).isFavorite(user.uid, stationId);
});

/// İstasyon detayı — önce mock'tan bak, yoksa Firestore'dan al
final stationDetailProvider =
    StreamProvider.family<ChargingStationEntity?, String>((ref, id) async* {
  // Önce mock listesinden bak — anında sonuç
  final mock = _mockStations.where((s) => s.id == id).firstOrNull;
  if (mock != null) {
    yield mock;
    // Firestore'da gerçek verisi varsa güncelle
    await for (final live in ref
        .watch(stationRepositoryProvider)
        .watchStation(id)
        .handleError((_) {})) {
      yield live;
    }
  } else {
    // Mock'ta yok — Firestore stream'ini dinle
    yield null; // loading yerine null göster
    await for (final live in ref
        .watch(stationRepositoryProvider)
        .watchStation(id)
        .handleError((_) {})) {
      yield live;
    }
  }
});

// ---------------------------------------------------------------------------
// Mock şarj istasyonları
// ---------------------------------------------------------------------------

ChargingSocketEntity _s(String id, SocketType type, double kw,
        [SocketStatus status = SocketStatus.available]) =>
    ChargingSocketEntity(
        id: id, type: type, powerKw: kw, status: status, isReservable: true);

final _t = DateTime(2025, 1, 1);

final List<ChargingStationEntity> _mockStations = [
  // ── İSTANBUL (8 istasyon) ─────────────────────────────────────────────
  ChargingStationEntity(
    id: 'ms_ist_1',
    name: 'ZES Maslak AVM',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 41.1086, lng: 29.0214),
    address: 'Büyükdere Cad. No:237, Maslak',
    city: 'İstanbul',
    sockets: [
      _s('s1', SocketType.ccs2, 180),
      _s('s2', SocketType.ccs2, 180),
      _s('s3', SocketType.acType2, 22)
    ],
    pricePerKwh: 12.50,
    status: 'available',
    reliabilityScore: 4.6,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 3,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_2',
    name: 'Eşarj Levent Metrocity',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 41.0699, lng: 29.0100),
    address: 'Büyükdere Cad. No:171, Levent',
    city: 'İstanbul',
    sockets: [_s('s1', SocketType.ccs2, 150), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.80,
    status: 'available',
    reliabilityScore: 4.4,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_3',
    name: 'Trugo Bağcılar TEM',
    network: StationNetwork.trugo,
    location: const StationLocation(lat: 41.0380, lng: 28.8550),
    address: 'TEM Otoyolu Yan Yol, Bağcılar',
    city: 'İstanbul',
    sockets: [
      _s('s1', SocketType.ccs2, 300),
      _s('s2', SocketType.ccs2, 300),
      _s('s3', SocketType.chademo, 50)
    ],
    pricePerKwh: 13.20,
    status: 'available',
    reliabilityScore: 4.7,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 3,
    totalSockets: 3,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_4',
    name: 'WAT Kadıköy Moda',
    network: StationNetwork.wat,
    location: const StationLocation(lat: 40.9800, lng: 29.0270),
    address: 'Moda Cad. No:15, Kadıköy',
    city: 'İstanbul',
    sockets: [
      _s('s1', SocketType.acType2, 22),
      _s('s2', SocketType.acType2, 22)
    ],
    pricePerKwh: 10.50,
    status: 'available',
    reliabilityScore: 4.2,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 1,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_5',
    name: 'Tesla Supercharger Ataşehir',
    network: StationNetwork.tesla,
    location: const StationLocation(lat: 40.9920, lng: 29.1270),
    address: 'Ataşehir Bulvarı, Ataşehir',
    city: 'İstanbul',
    sockets: [
      _s('s1', SocketType.tesla, 250),
      _s('s2', SocketType.tesla, 250),
      _s('s3', SocketType.tesla, 250),
      _s('s4', SocketType.tesla, 250)
    ],
    pricePerKwh: 14.00,
    status: 'available',
    reliabilityScore: 4.9,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 4,
    totalSockets: 4,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_6',
    name: 'ZES İstinye Park',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 41.1094, lng: 29.0600),
    address: 'İstinye Bayırı Cad., Sarıyer',
    city: 'İstanbul',
    sockets: [_s('s1', SocketType.ccs2, 180), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 12.50,
    status: 'available',
    reliabilityScore: 4.5,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 1,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_7',
    name: 'Eşarj Pendik Marina',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 40.8760, lng: 29.2330),
    address: 'Sahil Yolu, Pendik',
    city: 'İstanbul',
    sockets: [_s('s1', SocketType.ccs2, 120), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.80,
    status: 'available',
    reliabilityScore: 4.3,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ist_8',
    name: 'Shell Recharge Beşiktaş',
    network: StationNetwork.shell,
    location: const StationLocation(lat: 41.0430, lng: 29.0030),
    address: 'Barbaros Bulvarı, Beşiktaş',
    city: 'İstanbul',
    sockets: [_s('s1', SocketType.ccs2, 150), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 13.00,
    status: 'available',
    reliabilityScore: 4.4,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),

  // ── TEM OTOYOL KORİDORU ────────────────────────────────────────────────
  ChargingStationEntity(
    id: 'ms_hwy_1',
    name: 'Trugo Gebze TEM',
    network: StationNetwork.trugo,
    location: const StationLocation(lat: 40.7900, lng: 29.4400),
    address: 'TEM Otoyolu, Gebze',
    city: 'Kocaeli',
    sockets: [_s('s1', SocketType.ccs2, 300), _s('s2', SocketType.ccs2, 300)],
    pricePerKwh: 13.20,
    status: 'available',
    reliabilityScore: 4.8,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_hwy_2',
    name: 'ZES Bolu Dağı Tesisi',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 40.7300, lng: 31.5800),
    address: 'TEM Bolu Dağı Dinlenme Tesisi',
    city: 'Bolu',
    sockets: [_s('s1', SocketType.ccs2, 180), _s('s2', SocketType.ccs2, 180)],
    pricePerKwh: 12.50,
    status: 'available',
    reliabilityScore: 4.6,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_hwy_3',
    name: 'Eşarj Düzce Dinlenme',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 40.8400, lng: 31.1500),
    address: 'TEM Düzce Dinlenme Tesisi',
    city: 'Düzce',
    sockets: [_s('s1', SocketType.ccs2, 150), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.80,
    status: 'available',
    reliabilityScore: 4.4,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 1,
    totalSockets: 2,
    updatedAt: _t,
  ),

  // ── ANKARA (3 istasyon) ────────────────────────────────────────────────
  ChargingStationEntity(
    id: 'ms_ank_1',
    name: 'ZES Armada AVM Ankara',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 39.9010, lng: 32.8280),
    address: 'Eskişehir Yolu No:6, Söğütözü',
    city: 'Ankara',
    sockets: [
      _s('s1', SocketType.ccs2, 180),
      _s('s2', SocketType.ccs2, 180),
      _s('s3', SocketType.acType2, 22)
    ],
    pricePerKwh: 12.00,
    status: 'available',
    reliabilityScore: 4.5,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 3,
    totalSockets: 3,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ank_2',
    name: 'Trugo Ankara Kuzey Çevre',
    network: StationNetwork.trugo,
    location: const StationLocation(lat: 40.0600, lng: 32.8850),
    address: 'Kuzey Çevre Yolu, Keçiören',
    city: 'Ankara',
    sockets: [_s('s1', SocketType.ccs2, 300), _s('s2', SocketType.ccs2, 300)],
    pricePerKwh: 13.00,
    status: 'available',
    reliabilityScore: 4.8,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ank_3',
    name: 'Eşarj Kızılay',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 39.9208, lng: 32.8541),
    address: 'Atatürk Bulvarı, Çankaya',
    city: 'Ankara',
    sockets: [_s('s1', SocketType.ccs2, 120), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.50,
    status: 'available',
    reliabilityScore: 4.2,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 1,
    totalSockets: 2,
    updatedAt: _t,
  ),

  // ── İZMİR (2 istasyon) ────────────────────────────────────────────────
  ChargingStationEntity(
    id: 'ms_izm_1',
    name: 'ZES İzmir Forum AVM',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 38.4600, lng: 27.2100),
    address: 'Ankara Cad. No:1, Bayraklı',
    city: 'İzmir',
    sockets: [
      _s('s1', SocketType.ccs2, 180),
      _s('s2', SocketType.ccs2, 180),
      _s('s3', SocketType.acType2, 22)
    ],
    pricePerKwh: 12.20,
    status: 'available',
    reliabilityScore: 4.4,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 3,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_izm_2',
    name: 'Tesla Supercharger Alsancak',
    network: StationNetwork.tesla,
    location: const StationLocation(lat: 38.4350, lng: 27.1400),
    address: 'Kıbrıs Şehitleri Cad., Alsancak',
    city: 'İzmir',
    sockets: [
      _s('s1', SocketType.tesla, 250),
      _s('s2', SocketType.tesla, 250),
      _s('s3', SocketType.tesla, 250)
    ],
    pricePerKwh: 14.00,
    status: 'available',
    reliabilityScore: 4.9,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 3,
    totalSockets: 3,
    updatedAt: _t,
  ),

  // ── DİĞER ŞEHIRLER ────────────────────────────────────────────────────
  ChargingStationEntity(
    id: 'ms_brs_1',
    name: 'Eşarj Bursa Panora AVM',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 40.2100, lng: 28.9800),
    address: 'Panora AVM, Nilüfer',
    city: 'Bursa',
    sockets: [_s('s1', SocketType.ccs2, 150), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.80,
    status: 'available',
    reliabilityScore: 4.3,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ant_1',
    name: 'ZES Antalya TerraCity',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 36.8969, lng: 30.7133),
    address: 'Kundu Mah., Aksu',
    city: 'Antalya',
    sockets: [
      _s('s1', SocketType.ccs2, 180),
      _s('s2', SocketType.ccs2, 180),
      _s('s3', SocketType.acType2, 22)
    ],
    pricePerKwh: 12.50,
    status: 'available',
    reliabilityScore: 4.5,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 3,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ant_2',
    name: 'Trugo Antalya O-400',
    network: StationNetwork.trugo,
    location: const StationLocation(lat: 36.9500, lng: 30.6800),
    address: 'O-400 Otoyolu, Döşemealtı',
    city: 'Antalya',
    sockets: [_s('s1', SocketType.ccs2, 300), _s('s2', SocketType.ccs2, 300)],
    pricePerKwh: 13.00,
    status: 'available',
    reliabilityScore: 4.7,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_kon_1',
    name: 'ZES Konya Park AVM',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 37.8714, lng: 32.4846),
    address: 'Nalçacı Cad., Selçuklu',
    city: 'Konya',
    sockets: [_s('s1', SocketType.ccs2, 150), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 12.00,
    status: 'available',
    reliabilityScore: 4.3,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_esk_1',
    name: 'WAT Eskişehir Odunpazarı',
    network: StationNetwork.wat,
    location: const StationLocation(lat: 39.7767, lng: 30.5206),
    address: 'İki Eylül Cad., Odunpazarı',
    city: 'Eskişehir',
    sockets: [_s('s1', SocketType.ccs2, 120), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 10.80,
    status: 'available',
    reliabilityScore: 4.2,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_ada_1',
    name: 'ZES Adana Optimum AVM',
    network: StationNetwork.zes,
    location: const StationLocation(lat: 37.0000, lng: 35.3213),
    address: 'Optimum AVM, Yüreğir',
    city: 'Adana',
    sockets: [_s('s1', SocketType.ccs2, 180), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 12.00,
    status: 'available',
    reliabilityScore: 4.3,
    supportsReservation: true,
    photoUrls: const [],
    availableCount: 2,
    totalSockets: 2,
    updatedAt: _t,
  ),
  ChargingStationEntity(
    id: 'ms_trb_1',
    name: 'Eşarj Trabzon Forum AVM',
    network: StationNetwork.esarj,
    location: const StationLocation(lat: 41.0015, lng: 39.7178),
    address: 'Forum AVM, Ortahisar',
    city: 'Trabzon',
    sockets: [_s('s1', SocketType.ccs2, 120), _s('s2', SocketType.acType2, 22)],
    pricePerKwh: 11.80,
    status: 'available',
    reliabilityScore: 4.2,
    supportsReservation: false,
    photoUrls: const [],
    availableCount: 1,
    totalSockets: 2,
    updatedAt: _t,
  ),
];
