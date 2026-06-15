class TripLocation {
  const TripLocation({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;
}

enum TripStrategy { fastest, cheapest, balanced, safest }

class ChargingStopEntity {
  const ChargingStopEntity({
    required this.stationId,
    required this.stationName,
    required this.chargeMinutes,
    required this.costTl,
    this.lat,
    this.lng,
  });

  final String stationId;
  final String stationName;
  final int chargeMinutes;
  final double costTl;
  final double? lat;
  final double? lng;
}

class TripEntity {
  const TripEntity({
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
  final TripLocation origin;
  final TripLocation destination;
  final TripStrategy strategy;
  final double startSoc;
  final double distanceKm;
  final int driveMinutes;
  final int chargeMinutes;
  final double totalCostTl;
  final List<ChargingStopEntity> chargingStops;
  final DateTime createdAt;

  int get totalMinutes => driveMinutes + chargeMinutes;
}

class VehiclePreset {
  const VehiclePreset({
    required this.id,
    required this.brand,
    required this.model,
    required this.batteryKwh,
    required this.wltpRangeKm,
    required this.efficiencyKwhPer100km,
  });

  final String id;
  final String brand;
  final String model;
  final double batteryKwh;
  final double wltpRangeKm;
  final double efficiencyKwhPer100km;

  String get displayName => '$brand $model';

  static const presets = [
    VehiclePreset(
      id: 'tesla_model_y',
      brand: 'Tesla',
      model: 'Model Y LR',
      batteryKwh: 75,
      wltpRangeKm: 533,
      efficiencyKwhPer100km: 16.5,
    ),
    VehiclePreset(
      id: 'togg_t10x',
      brand: 'Togg',
      model: 'T10X',
      batteryKwh: 88.5,
      wltpRangeKm: 523,
      efficiencyKwhPer100km: 18.2,
    ),
    VehiclePreset(
      id: 'bmw_ix',
      brand: 'BMW',
      model: 'iX xDrive50',
      batteryKwh: 111.5,
      wltpRangeKm: 630,
      efficiencyKwhPer100km: 19.8,
    ),
    VehiclePreset(
      id: 'hyundai_ioniq5',
      brand: 'Hyundai',
      model: 'Ioniq 5',
      batteryKwh: 77.4,
      wltpRangeKm: 481,
      efficiencyKwhPer100km: 17.1,
    ),
    VehiclePreset(
      id: 'mg4',
      brand: 'MG',
      model: '4 Electric',
      batteryKwh: 64,
      wltpRangeKm: 450,
      efficiencyKwhPer100km: 16.8,
    ),
  ];
}

class TripPlanResult {
  const TripPlanResult({
    required this.distanceKm,
    required this.driveMinutes,
    required this.chargeMinutes,
    required this.totalCostTl,
    required this.chargingStops,
    required this.availableRangeKm,
  });

  final double distanceKm;
  final int driveMinutes;
  final int chargeMinutes;
  final double totalCostTl;
  final List<ChargingStopEntity> chargingStops;
  final double availableRangeKm;
}
