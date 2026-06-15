import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  static const _collection = 'vehicles';
  static const _users = 'users';

  @override
  Stream<List<VehicleEntity>> watchUserVehicles(String userId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final vehicles = s.docs
          .map(VehicleModel.fromFirestore)
          .map((m) => m.toEntity())
          .toList();
      vehicles.sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now());
      });
      return vehicles;
    });
  }

  @override
  Future<VehicleEntity?> getPrimaryVehicle(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      final all = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();
      if (all.docs.isEmpty) return null;
      return VehicleModel.fromFirestore(all.docs.first).toEntity();
    }
    return VehicleModel.fromFirestore(snap.docs.first).toEntity();
  }

  @override
  Future<void> addVehicle(VehicleEntity vehicle) async {
    final model = VehicleModel.fromEntity(vehicle);
    final batch = _firestore.batch();

    if (vehicle.isPrimary) {
      final existing = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: vehicle.ownerId)
          .where('isPrimary', isEqualTo: true)
          .get();
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isPrimary': false});
      }
    }

    batch.set(
      _firestore.collection(_collection).doc(vehicle.id),
      model.toFirestore(),
    );
    batch.update(_firestore.collection(_users).doc(vehicle.ownerId), {
      'vehicleIds': FieldValue.arrayUnion([vehicle.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> updateVehicle(VehicleEntity vehicle) async {
    await _firestore
        .collection(_collection)
        .doc(vehicle.id)
        .update(VehicleModel.fromEntity(vehicle).toFirestore());
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    final doc = await _firestore.collection(_collection).doc(vehicleId).get();
    if (!doc.exists) return;
    final ownerId = doc.data()!['ownerId'] as String;
    final batch = _firestore.batch();
    batch.delete(doc.reference);
    batch.update(_firestore.collection(_users).doc(ownerId), {
      'vehicleIds': FieldValue.arrayRemove([vehicleId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> setPrimaryVehicle(String userId, String vehicleId) async {
    final batch = _firestore.batch();
    final all = await _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: userId)
        .get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {
        'isPrimary': doc.id == vehicleId,
      });
    }
    await batch.commit();
  }
}
