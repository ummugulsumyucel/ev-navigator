import '../entities/service_entity.dart';

abstract class ServiceRepository {
  Stream<List<ServiceEntity>> watchServices();

  Future<void> createAppointment({
    required String userId,
    required String serviceId,
    required String serviceName,
    required String serviceType,
    required DateTime date,
  });

  Stream<List<AppointmentEntity>> watchUserAppointments(String userId);
}
