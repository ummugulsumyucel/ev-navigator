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
  return const LatLng(41.0151, 28.9795);
});

class MapBoundsState {
  const MapBoundsState({
    this.minLat = 40.5,
    this.maxLat = 41.5,
    this.minLng = 28.0,
    this.maxLng = 30.0,
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
  }) {
    return MapBoundsState(
      minLat: minLat ?? this.minLat,
      maxLat: maxLat ?? this.maxLat,
      minLng: minLng ?? this.minLng,
      maxLng: maxLng ?? this.maxLng,
    );
  }
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
  }) {
    return MapViewState(
      bounds: bounds ?? this.bounds,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MapViewNotifier extends StateNotifier<MapViewState> {
  MapViewNotifier() : super(const MapViewState());

  /// Kullanıcı konumuna göre başlangıç bounds'ını ayarla (~10 km yarıçap)
  void initFromLocation(double lat, double lng) {
    const delta = 0.09; // ~10 km
    if (state.bounds.minLat == 40.5 && state.bounds.maxLat == 41.5) {
      // Sadece ilk açılışta override et
      state = state.copyWith(
        bounds: MapBoundsState(
          minLat: lat - delta,
          maxLat: lat + delta,
          minLng: lng - delta,
          maxLng: lng + delta,
        ),
      );
    }
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

  void applyFilters(StationFiltersEntity filters) {
    state = state.copyWith(filters: filters);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }
}

final mapViewNotifierProvider =
    StateNotifierProvider<MapViewNotifier, MapViewState>((ref) {
  return MapViewNotifier();
});

final stationsStreamProvider =
    StreamProvider<List<ChargingStationEntity>>((ref) {
  final viewState = ref.watch(mapViewNotifierProvider);
  return ref.watch(stationRepositoryProvider).watchStations(
        minLat: viewState.bounds.minLat,
        maxLat: viewState.bounds.maxLat,
        minLng: viewState.bounds.minLng,
        maxLng: viewState.bounds.maxLng,
        filters: viewState.filters,
      );
});

final filteredStationsProvider =
    Provider<AsyncValue<List<ChargingStationEntity>>>((ref) {
  final stationsAsync = ref.watch(stationsStreamProvider);
  final query = ref.watch(mapViewNotifierProvider).searchQuery.toLowerCase();

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
  return ref.watch(stationRepositoryProvider).getNearbyStations(
        lat: location.latitude,
        lng: location.longitude,
      );
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, stationId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(stationRepositoryProvider).isFavorite(user.uid, stationId);
});
