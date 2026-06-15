class VehicleEntity {
  const VehicleEntity({
    required this.id,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.year,
    required this.batteryKwh,
    required this.wltpRangeKm,
    this.vin,
    this.plate,
    this.isPrimary = false,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String brand;
  final String model;
  final int year;
  final double batteryKwh;
  final double wltpRangeKm;
  final String? vin;
  final String? plate;
  final bool isPrimary;
  final DateTime? createdAt;

  String get displayName => '$brand $model';
  double get efficiencyKwhPer100km =>
      batteryKwh > 0 ? (batteryKwh / wltpRangeKm) * 100 : 18.0;
}
