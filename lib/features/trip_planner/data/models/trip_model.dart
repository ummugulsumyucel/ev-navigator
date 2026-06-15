import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/trip_entity.dart';

class TripModel {
  const TripModel({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.origin,
    required this.destination,
    required this.strategy,
    required this.startSoc,
    required this.distanceKm,
    required this.driveMinutes,
    required this.chargeMinutes,
    required this.totalCostTl,
    required this.chargingStops,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String vehicleId;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final String strategy;
  final double startSoc;
  final double distanceKm;
  final int driveMinutes;
  final int chargeMinutes;
  final double totalCostTl;
  final List<Map<String, dynamic>> chargingStops;
  final DateTime createdAt;

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TripModel(
      id: doc.id,
      userId: data['userId'] as String,
      vehicleId: data['vehicleId'] as String? ?? '',
      origin: Map<String, dynamic>.from(data['origin'] as Map),
      destination: Map<String, dynamic>.from(data['destination'] as Map),
      strategy: data['strategy'] as String? ?? 'balanced',
      startSoc: (data['startSoc'] as num?)?.toDouble() ?? 80,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      driveMinutes: data['driveMinutes'] as int? ?? 0,
      chargeMinutes: data['chargeMinutes'] as int? ?? 0,
      totalCostTl: (data['totalCostTl'] as num?)?.toDouble() ?? 0,
      chargingStops: List<Map<String, dynamic>>.from(
        data['chargingStops'] ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'vehicleId': vehicleId,
        'origin': origin,
        'destination': destination,
        'strategy': strategy,
        'startSoc': startSoc,
        'distanceKm': distanceKm,
        'driveMinutes': driveMinutes,
        'chargeMinutes': chargeMinutes,
        'totalCostTl': totalCostTl,
        'chargingStops': chargingStops,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  TripEntity toEntity() => TripEntity(
        id: id,
        userId: userId,
        vehicleId: vehicleId,
        origin: TripLocation(
          name: origin['name'] as String? ?? '',
          lat: (origin['lat'] as num).toDouble(),
          lng: (origin['lng'] as num).toDouble(),
        ),
        destination: TripLocation(
          name: destination['name'] as String? ?? '',
          lat: (destination['lat'] as num).toDouble(),
          lng: (destination['lng'] as num).toDouble(),
        ),
        strategy: TripStrategy.values.firstWhere(
          (s) => s.name == strategy,
          orElse: () => TripStrategy.balanced,
        ),
        startSoc: startSoc,
        distanceKm: distanceKm,
        driveMinutes: driveMinutes,
        chargeMinutes: chargeMinutes,
        totalCostTl: totalCostTl,
        chargingStops: chargingStops.map((s) {
          return ChargingStopEntity(
            stationId: s['stationId'] as String? ?? '',
            stationName: s['stationName'] as String? ?? '',
            chargeMinutes: s['chargeMinutes'] as int? ?? 0,
            costTl: (s['costTl'] as num?)?.toDouble() ?? 0,
            lat: (s['lat'] as num?)?.toDouble(),
            lng: (s['lng'] as num?)?.toDouble(),
          );
        }).toList(),
        createdAt: createdAt,
      );

  static TripModel fromEntity(TripEntity entity) => TripModel(
        id: entity.id,
        userId: entity.userId,
        vehicleId: entity.vehicleId,
        origin: {
          'name': entity.origin.name,
          'lat': entity.origin.lat,
          'lng': entity.origin.lng,
        },
        destination: {
          'name': entity.destination.name,
          'lat': entity.destination.lat,
          'lng': entity.destination.lng,
        },
        strategy: entity.strategy.name,
        startSoc: entity.startSoc,
        distanceKm: entity.distanceKm,
        driveMinutes: entity.driveMinutes,
        chargeMinutes: entity.chargeMinutes,
        totalCostTl: entity.totalCostTl,
        chargingStops: entity.chargingStops
            .map((s) => {
                  'stationId': s.stationId,
                  'stationName': s.stationName,
                  'chargeMinutes': s.chargeMinutes,
                  'costTl': s.costTl,
                  if (s.lat != null) 'lat': s.lat,
                  if (s.lng != null) 'lng': s.lng,
                })
            .toList(),
        createdAt: entity.createdAt,
      );
}
