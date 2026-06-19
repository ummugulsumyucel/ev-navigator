import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/repositories/station_repository.dart';
import '../models/station_model.dart';
import '../models/review_model.dart';

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(this._firestore, {HiveCacheService? cache})
      : _cache = cache ?? HiveCacheService();

  final FirebaseFirestore _firestore;
  final HiveCacheService _cache;

  static const _stations = 'charging_stations';
  static const _reviews = 'station_reviews';
  static const _favorites = 'favorites';

  @override
  Stream<List<ChargingStationEntity>> watchStations({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    StationFiltersEntity? filters,
  }) {
    return _firestore
        .collection(_stations)
        .where('location.lat', isGreaterThanOrEqualTo: minLat)
        .where('location.lat', isLessThanOrEqualTo: maxLat)
        .snapshots()
        .map((snapshot) {
      final stations = snapshot.docs
          .map(StationModel.fromFirestore)
          .map((m) => m.toEntity())
          .where((s) => s.location.lng >= minLng && s.location.lng <= maxLng)
          .where((s) => _matchesFilters(s, filters))
          .toList();
      return stations;
    });
  }

  bool _matchesFilters(
    ChargingStationEntity station,
    StationFiltersEntity? filters,
  ) {
    if (filters == null || !filters.isActive) return true;
    if (filters.networks.isNotEmpty &&
        !filters.networks.contains(station.network)) {
      return false;
    }
    if (filters.onlyAvailable && station.availableCount == 0) return false;
    if (filters.minReliability != null &&
        station.reliabilityScore < filters.minReliability!) {
      return false;
    }
    if (filters.maxPrice != null &&
        (station.pricePerKwh == null ||
            station.pricePerKwh! > filters.maxPrice!)) {
      return false;
    }
    if (filters.socketTypes.isNotEmpty) {
      final hasType =
          station.sockets.any((s) => filters.socketTypes.contains(s.type));
      if (!hasType) return false;
    }
    if (filters.minPowerKw != null) {
      final maxPower = station.sockets.fold<double>(
        0,
        (m, s) => s.powerKw > m ? s.powerKw : m,
      );
      if (maxPower < filters.minPowerKw!) return false;
    }
    return true;
  }

  @override
  Stream<List<ChargingStationEntity>> watchAllStations({
    StationFiltersEntity? filters,
  }) {
    return _firestore
        .collection(_stations)
        .limit(500)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(StationModel.fromFirestore)
          .map((m) => m.toEntity())
          .where((s) => _matchesFilters(s, filters))
          .toList();
    });
  }

  @override
  Future<ChargingStationEntity?> getStation(String id) async {
    final doc = await _firestore.collection(_stations).doc(id).get();
    if (!doc.exists) return null;
    return StationModel.fromFirestore(doc).toEntity();
  }

  @override
  Stream<ChargingStationEntity> watchStation(String id) {
    return _firestore
        .collection(_stations)
        .doc(id)
        .snapshots()
        .map((doc) => StationModel.fromFirestore(doc).toEntity());
  }

  @override
  Future<List<StationReviewEntity>> getReviews(
    String stationId, {
    int limit = 20,
    Object? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_reviews)
        .where('stationId', isEqualTo: stationId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter is DocumentSnapshot) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(ReviewModel.fromFirestore)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<void> addReview(StationReviewEntity review) async {
    final model = ReviewModel.fromEntity(review);
    await _firestore
        .collection(_reviews)
        .doc(review.id)
        .set(model.toFirestore());
  }

  @override
  Future<void> toggleFavorite(String userId, String stationId) async {
    final id = '${userId}_$stationId';
    final doc = await _firestore.collection(_favorites).doc(id).get();
    if (doc.exists) {
      await _firestore.collection(_favorites).doc(id).delete();
    } else {
      await _firestore.collection(_favorites).doc(id).set({
        'userId': userId,
        'stationId': stationId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<bool> isFavorite(String userId, String stationId) async {
    final id = '${userId}_$stationId';
    final doc = await _firestore.collection(_favorites).doc(id).get();
    return doc.exists;
  }

  @override
  Stream<List<String>> watchFavoriteStationIds(String userId) {
    return _firestore
        .collection(_favorites)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
            (s) => s.docs.map((d) => d.data()['stationId'] as String).toList());
  }

  @override
  Future<List<ChargingStationEntity>> getNearbyStations({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 10,
  }) async {
    final cacheKey =
        'nearby_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';

    try {
      final snapshot = await _firestore.collection(_stations).limit(100).get();
      final stations = snapshot.docs
          .map(StationModel.fromFirestore)
          .map((m) => m.toEntity())
          .where((s) =>
              _distanceKm(lat, lng, s.location.lat, s.location.lng) <= radiusKm)
          .toList();
      stations.sort((a, b) => _distanceKm(
              lat, lng, a.location.lat, a.location.lng)
          .compareTo(_distanceKm(lat, lng, b.location.lat, b.location.lng)));
      final result = stations.take(limit).toList();

      await _cache.cacheStations(cacheKey, {
        'ids': result.map((s) => s.id).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      });
      for (final s in result) {
        await _cache.cacheStationDetail(s.id, _stationToMap(s));
      }
      return result;
    } catch (_) {
      final cached = _readCachedNearby(cacheKey);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Map<String, dynamic> _stationToMap(ChargingStationEntity s) => {
        'id': s.id,
        'name': s.name,
        'network': s.network.name,
        'lat': s.location.lat,
        'lng': s.location.lng,
        'address': s.address,
        'city': s.city,
        'availableCount': s.availableCount,
        'totalSockets': s.totalSockets,
        'pricePerKwh': s.pricePerKwh,
      };

  List<ChargingStationEntity> _readCachedNearby(String cacheKey) {
    final meta = _cache.getCachedStations(cacheKey);
    if (meta == null) return [];
    final ids = List<String>.from(meta['ids'] ?? []);
    final stations = <ChargingStationEntity>[];
    for (final id in ids) {
      final detail = _cache.getCachedStationDetail(id);
      if (detail != null) {
        stations.add(_mapToEntity(detail));
      }
    }
    return stations;
  }

  ChargingStationEntity _mapToEntity(Map<String, dynamic> d) {
    return ChargingStationEntity(
      id: d['id'] as String,
      name: d['name'] as String? ?? '',
      network: StationNetwork.values.firstWhere(
        (n) => n.name == (d['network'] as String? ?? 'zes'),
        orElse: () => StationNetwork.zes,
      ),
      location: StationLocation(
        lat: (d['lat'] as num).toDouble(),
        lng: (d['lng'] as num).toDouble(),
      ),
      address: d['address'] as String? ?? '',
      city: d['city'] as String? ?? '',
      sockets: const [],
      status: 'available',
      reliabilityScore: 3.0,
      supportsReservation: false,
      photoUrls: const [],
      availableCount: d['availableCount'] as int? ?? 0,
      totalSockets: d['totalSockets'] as int? ?? 0,
      updatedAt: DateTime.now(),
      pricePerKwh: (d['pricePerKwh'] as num?)?.toDouble(),
    );
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.asin(math.sqrt(a));
  }

  double _rad(double deg) => deg * math.pi / 180;
}
