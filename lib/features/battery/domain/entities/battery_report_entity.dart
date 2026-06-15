class BatteryReportEntity {
  const BatteryReportEntity({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.soh,
    required this.soc,
    required this.temperatureC,
    required this.chargeCycles,
    required this.realRangeKm,
    required this.efficiencyKwhPer100km,
    required this.recordedAt,
  });

  final String id;
  final String userId;
  final String vehicleId;
  final double soh;
  final double soc;
  final double temperatureC;
  final int chargeCycles;
  final double realRangeKm;
  final double efficiencyKwhPer100km;
  final DateTime recordedAt;
}

enum BatteryChartPeriod { daily, weekly, monthly }
