import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(
    directionsApi: ref.watch(directionsApiProvider),
    stationRepository: ref.watch(stationRepositoryProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final userTripsProvider = StreamProvider<List<TripEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(tripRepositoryProvider).watchUserTrips(user.uid);
});

class TripPlannerController extends StateNotifier<AsyncValue<TripPlanResult?>> {
  TripPlannerController(this._repository) : super(const AsyncData(null));

  final TripRepository _repository;

  Future<TripPlanResult?> plan({
    required TripLocation origin,
    required TripLocation destination,
    required VehiclePreset vehicle,
    required double startSoc,
    required TripStrategy strategy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _repository.planTrip(
        origin: origin,
        destination: destination,
        vehicle: vehicle,
        startSoc: startSoc,
        strategy: strategy,
      );
    });
    return state.valueOrNull;
  }

  Future<void> saveCurrentTrip({
    required TripPlanResult result,
    required TripLocation origin,
    required TripLocation destination,
    required VehiclePreset vehicle,
    required double startSoc,
    required TripStrategy strategy,
    required String userId,
  }) async {
    final trip = TripEntity(
      id: const Uuid().v4(),
      userId: userId,
      vehicleId: vehicle.id,
      origin: origin,
      destination: destination,
      strategy: strategy,
      startSoc: startSoc,
      distanceKm: result.distanceKm,
      driveMinutes: result.driveMinutes,
      chargeMinutes: result.chargeMinutes,
      totalCostTl: result.totalCostTl,
      chargingStops: result.chargingStops,
      createdAt: DateTime.now(),
    );
    await _repository.saveTrip(trip);
  }
}

final tripPlannerControllerProvider =
    StateNotifierProvider<TripPlannerController, AsyncValue<TripPlanResult?>>(
        (ref) {
  return TripPlannerController(ref.watch(tripRepositoryProvider));
});
