import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/battery_report_entity.dart';

class BatteryReportModel {
  const BatteryReportModel({
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

  factory BatteryReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BatteryReportModel(
      id: doc.id,
      userId: data['userId'] as String,
      vehicleId: data['vehicleId'] as String? ?? '',
      soh: (data['soh'] as num?)?.toDouble() ?? 100,
      soc: (data['soc'] as num?)?.toDouble() ?? 80,
      temperatureC: (data['temperatureC'] as num?)?.toDouble() ?? 25,
      chargeCycles: data['chargeCycles'] as int? ?? 0,
      realRangeKm: (data['realRangeKm'] as num?)?.toDouble() ?? 0,
      efficiencyKwhPer100km:
          (data['efficiencyKwhPer100km'] as num?)?.toDouble() ?? 18,
      recordedAt:
          (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  BatteryReportEntity toEntity() => BatteryReportEntity(
        id: id,
        userId: userId,
        vehicleId: vehicleId,
        soh: soh,
        soc: soc,
        temperatureC: temperatureC,
        chargeCycles: chargeCycles,
        realRangeKm: realRangeKm,
        efficiencyKwhPer100km: efficiencyKwhPer100km,
        recordedAt: recordedAt,
      );
}
