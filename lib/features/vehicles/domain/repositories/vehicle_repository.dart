import '../entities/vehicle_entity.dart';

abstract class VehicleRepository {
  Stream<List<VehicleEntity>> watchUserVehicles(String userId);

  Future<VehicleEntity?> getPrimaryVehicle(String userId);

  Future<void> addVehicle(VehicleEntity vehicle);

  Future<void> updateVehicle(VehicleEntity vehicle);

  Future<void> deleteVehicle(String vehicleId);

  Future<void> setPrimaryVehicle(String userId, String vehicleId);
}
