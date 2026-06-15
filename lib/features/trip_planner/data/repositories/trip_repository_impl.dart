import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/network/dio_client.dart';
import '../../../map/domain/entities/station_entity.dart';
import '../../../map/domain/repositories/station_repository.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({
    required DirectionsApiClient directionsApi,
    required StationRepository stationRepository,
    required FirebaseFirestore firestore,
  })  : _directionsApi = directionsApi,
        _stationRepository = stationRepository,
        _firestore = firestore;

  final DirectionsApiClient _directionsApi;
  final StationRepository _stationRepository;
  final FirebaseFirestore _firestore;

  static const _trips = 'trips';
  static const _reserveSoc = 0.15;
  static const _targetChargeSoc = 0.80;

  @override
  Future<TripPlanResult> planTrip({
    required TripLocation origin,
    required TripLocation destination,
    required VehiclePreset vehicle,
    required double startSoc,
    required TripStrategy strategy,
  }) async {
    final directions = await _directionsApi.getDirections(
      originLat: origin.lat,
      originLng: origin.lng,
      destLat: destination.lat,
      destLng: destination.lng,
    );

    final route = (directions['routes'] as List).first as Map<String, dynamic>;
    final leg = (route['legs'] as List).first as Map<String, dynamic>;
    final distanceM = (leg['distance'] as Map)['value'] as num;
    final durationS = (leg['duration'] as Map)['value'] as num;
    final distanceKm = distanceM / 1000;
    final driveMinutes = (durationS / 60).ceil();

    final availableRangeKm = vehicle.wltpRangeKm * (startSoc / 100) * 0.85;

    if (distanceKm <= availableRangeKm * (1 - _reserveSoc)) {
      return TripPlanResult(
        distanceKm: distanceKm,
        driveMinutes: driveMinutes,
        chargeMinutes: 0,
        totalCostTl: 0,
        chargingStops: const [],
        availableRangeKm: availableRangeKm,
      );
    }

    final allStations = await _stationRepository.getNearbyStations(
      lat: (origin.lat + destination.lat) / 2,
      lng: (origin.lng + destination.lng) / 2,
      radiusKm: distanceKm / 2 + 50,
      limit: 50,
    );

    final routeStations = allStations.where((s) {
      return _distanceToSegmentKm(
            s.location.lat,
            s.location.lng,
            origin.lat,
            origin.lng,
            destination.lat,
            destination.lng,
          ) <
          30;
    }).toList();

    routeStations.sort((a, b) {
      final distA =
          _distanceKm(origin.lat, origin.lng, a.location.lat, a.location.lng);
      final distB =
          _distanceKm(origin.lat, origin.lng, b.location.lat, b.location.lng);
      return distA.compareTo(distB);
    });

    final sortedStations = _sortByStrategy(routeStations, strategy);
    final stops = <ChargingStopEntity>[];
    var remainingKm = distanceKm;
    var currentRangeKm = availableRangeKm;
    var totalChargeMinutes = 0;
    var totalCost = 0.0;
    var usedStationIds = <String>{};

    for (final station in sortedStations) {
      if (remainingKm <= currentRangeKm * (1 - _reserveSoc)) break;
      if (usedStationIds.contains(station.id)) continue;
      if (station.availableCount == 0 && strategy != TripStrategy.safest) {
        continue;
      }

      final distToStation = _distanceKm(
        origin.lat,
        origin.lng,
        station.location.lat,
        station.location.lng,
      );
      if (distToStation > remainingKm) continue;

      final chargeKwh = vehicle.batteryKwh * (_targetChargeSoc - _reserveSoc);
      final chargeMinutes = (chargeKwh /
              (station.sockets.isNotEmpty
                  ? station.sockets.map((s) => s.powerKw).reduce(math.max)
                  : 50) *
              60)
          .ceil();
      final price = station.pricePerKwh ?? 12.0;
      final cost = chargeKwh * price;

      stops.add(ChargingStopEntity(
        stationId: station.id,
        stationName: station.name,
        chargeMinutes: chargeMinutes.clamp(15, 60),
        costTl: cost,
        lat: station.location.lat,
        lng: station.location.lng,
      ));

      usedStationIds.add(station.id);
      totalChargeMinutes += chargeMinutes.clamp(15, 60);
      totalCost += cost;
      currentRangeKm = vehicle.wltpRangeKm * _targetChargeSoc * 0.85;
      remainingKm -= distToStation;

      if (stops.length >= 5) break;
    }

    return TripPlanResult(
      distanceKm: distanceKm,
      driveMinutes: driveMinutes,
      chargeMinutes: totalChargeMinutes,
      totalCostTl: totalCost,
      chargingStops: stops,
      availableRangeKm: availableRangeKm,
    );
  }

  List<ChargingStationEntity> _sortByStrategy(
    List<ChargingStationEntity> stations,
    TripStrategy strategy,
  ) {
    final list = List<ChargingStationEntity>.from(stations);
    switch (strategy) {
      case TripStrategy.cheapest:
        list.sort((a, b) {
          final priceA = a.pricePerKwh ?? 99;
          final priceB = b.pricePerKwh ?? 99;
          return priceA.compareTo(priceB);
        });
      case TripStrategy.safest:
        list.sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));
      case TripStrategy.fastest:
        list.sort((a, b) {
          final powerA = a.sockets.isEmpty
              ? 0.0
              : a.sockets.map((s) => s.powerKw).reduce(math.max);
          final powerB = b.sockets.isEmpty
              ? 0.0
              : b.sockets.map((s) => s.powerKw).reduce(math.max);
          return powerB.compareTo(powerA);
        });
      case TripStrategy.balanced:
        list.sort((a, b) {
          final scoreA = a.reliabilityScore * 2 - (a.pricePerKwh ?? 12);
          final scoreB = b.reliabilityScore * 2 - (b.pricePerKwh ?? 12);
          return scoreB.compareTo(scoreA);
        });
    }
    return list;
  }

  @override
  Future<void> saveTrip(TripEntity trip) async {
    final model = TripModel.fromEntity(trip);
    await _firestore.collection(_trips).doc(trip.id).set(model.toFirestore());
  }

  @override
  Stream<List<TripEntity>> watchUserTrips(String userId) {
    return _firestore
        .collection(_trips)
        .where('userId', isEqualTo: userId)
        .limit(20)
        .snapshots()
        .map((s) {
      final entities =
          s.docs.map(TripModel.fromFirestore).map((m) => m.toEntity()).toList();
      // Bileşik index gerektirmemek için sıralamayı Dart tarafında yapıyoruz.
      entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entities;
    });
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

  double _distanceToSegmentKm(
    double pLat,
    double pLng,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    final midLat = (aLat + bLat) / 2;
    final midLng = (aLng + bLng) / 2;
    return _distanceKm(pLat, pLng, midLat, midLng);
  }

  double _rad(double deg) => deg * math.pi / 180;
}
