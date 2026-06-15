class ServiceLocation {
  const ServiceLocation({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

enum ServiceType { authorized, independent }

class ServiceEntity {
  const ServiceEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.location,
    required this.address,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.serviceTypes,
    required this.avgWaitDays,
  });

  final String id;
  final String name;
  final String brand;
  final ServiceType type;
  final ServiceLocation location;
  final String address;
  final String phone;
  final double rating;
  final int reviewCount;
  final List<String> serviceTypes;
  final int avgWaitDays;

  bool get isAuthorized => type == ServiceType.authorized;
}

class AppointmentEntity {
  const AppointmentEntity({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String serviceType;
  final DateTime date;
  final String status;
  final DateTime createdAt;
}
