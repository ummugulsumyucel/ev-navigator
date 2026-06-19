import '../entities/station_entity.dart';

abstract class StationRepository {
  Stream<List<ChargingStationEntity>> watchStations({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    StationFiltersEntity? filters,
  });

  /// Türkiye geneli tüm istasyonlar (arama için)
  Stream<List<ChargingStationEntity>> watchAllStations({
    StationFiltersEntity? filters,
  });

  Future<ChargingStationEntity?> getStation(String id);

  Stream<ChargingStationEntity> watchStation(String id);

  Future<List<StationReviewEntity>> getReviews(
    String stationId, {
    int limit = 20,
    Object? startAfter,
  });

  Future<void> addReview(StationReviewEntity review);

  Future<void> toggleFavorite(String userId, String stationId);
  Future<bool> isFavorite(String userId, String stationId);
  Stream<List<String>> watchFavoriteStationIds(String userId);

  Future<List<ChargingStationEntity>> getNearbyStations({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 10,
  });
}
