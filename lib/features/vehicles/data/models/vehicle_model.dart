import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_entity.dart';

class VehicleModel {
  const VehicleModel({
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

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int? ?? DateTime.now().year,
      batteryKwh: (data['batteryKwh'] as num?)?.toDouble() ?? 60,
      wltpRangeKm: (data['wltpRangeKm'] as num?)?.toDouble() ?? 400,
      vin: data['vin'] as String?,
      plate: data['plate'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'brand': brand,
        'model': model,
        'year': year,
        'batteryKwh': batteryKwh,
        'wltpRangeKm': wltpRangeKm,
        if (vin != null) 'vin': vin,
        if (plate != null) 'plate': plate,
        'isPrimary': isPrimary,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  VehicleEntity toEntity() => VehicleEntity(
        id: id,
        ownerId: ownerId,
        brand: brand,
        model: model,
        year: year,
        batteryKwh: batteryKwh,
        wltpRangeKm: wltpRangeKm,
        vin: vin,
        plate: plate,
        isPrimary: isPrimary,
        createdAt: createdAt,
      );

  static VehicleModel fromEntity(VehicleEntity entity) => VehicleModel(
        id: entity.id,
        ownerId: entity.ownerId,
        brand: entity.brand,
        model: entity.model,
        year: entity.year,
        batteryKwh: entity.batteryKwh,
        wltpRangeKm: entity.wltpRangeKm,
        vin: entity.vin,
        plate: entity.plate,
        isPrimary: entity.isPrimary,
        createdAt: entity.createdAt,
      );
}
