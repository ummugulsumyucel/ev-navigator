import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_entity.dart';

class ServiceModel {
  const ServiceModel({
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
  final String type;
  final Map<String, double> location;
  final String address;
  final String phone;
  final double rating;
  final int reviewCount;
  final List<String> serviceTypes;
  final int avgWaitDays;

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final loc = data['location'] as Map<String, dynamic>? ?? {};
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      type: data['type'] as String? ?? 'independent',
      location: {
        'lat': (loc['lat'] as num?)?.toDouble() ?? 0,
        'lng': (loc['lng'] as num?)?.toDouble() ?? 0,
      },
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      serviceTypes: List<String>.from(data['serviceTypes'] ?? []),
      avgWaitDays: data['avgWaitDays'] as int? ?? 3,
    );
  }

  ServiceEntity toEntity() => ServiceEntity(
        id: id,
        name: name,
        brand: brand,
        type: type == 'authorized'
            ? ServiceType.authorized
            : ServiceType.independent,
        location: ServiceLocation(
          lat: location['lat']!,
          lng: location['lng']!,
        ),
        address: address,
        phone: phone,
        rating: rating,
        reviewCount: reviewCount,
        serviceTypes: serviceTypes,
        avgWaitDays: avgWaitDays,
      );
}
