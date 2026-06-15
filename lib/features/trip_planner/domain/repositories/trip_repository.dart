import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<TripPlanResult> planTrip({
    required TripLocation origin,
    required TripLocation destination,
    required VehiclePreset vehicle,
    required double startSoc,
    required TripStrategy strategy,
  });

  Future<void> saveTrip(TripEntity trip);

  Stream<List<TripEntity>> watchUserTrips(String userId);
}
