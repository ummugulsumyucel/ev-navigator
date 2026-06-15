import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(ref.watch(firestoreProvider));
});

final userVehiclesProvider = StreamProvider<List<VehicleEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(vehicleRepositoryProvider).watchUserVehicles(user.uid);
});

final primaryVehicleProvider = FutureProvider<VehicleEntity?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(vehicleRepositoryProvider).getPrimaryVehicle(user.uid);
});

class VehicleController extends StateNotifier<AsyncValue<void>> {
  VehicleController(this._repository) : super(const AsyncData(null));

  final VehicleRepository _repository;

  Future<void> addVehicle(VehicleEntity vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.addVehicle(vehicle));
  }

  Future<void> deleteVehicle(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteVehicle(id));
  }

  Future<void> setPrimary(String userId, String vehicleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.setPrimaryVehicle(userId, vehicleId),
    );
  }
}

final vehicleControllerProvider =
    StateNotifierProvider<VehicleController, AsyncValue<void>>((ref) {
  return VehicleController(ref.watch(vehicleRepositoryProvider));
});
