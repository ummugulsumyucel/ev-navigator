import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/station_entity.dart';

class StationModel {
  const StationModel({
    required this.id,
    required this.name,
    required this.network,
    required this.location,
    required this.address,
    required this.city,
    required this.sockets,
    this.pricePerKwh,
    required this.status,
    required this.reliabilityScore,
    required this.supportsReservation,
    required this.photoUrls,
    required this.availableCount,
    required this.totalSockets,
    required this.updatedAt,
    this.geohash,
  });

  final String id;
  final String name;
  final String network;
  final Map<String, double> location;
  final String address;
  final String city;
  final List<Map<String, dynamic>> sockets;
  final double? pricePerKwh;
  final String status;
  final double reliabilityScore;
  final bool supportsReservation;
  final List<String> photoUrls;
  final int availableCount;
  final int totalSockets;
  final DateTime updatedAt;
  final String? geohash;

  factory StationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final loc = data['location'] as Map<String, dynamic>? ?? {};
    return StationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      network: data['network'] as String? ?? 'zes',
      location: {
        'lat': (loc['lat'] as num?)?.toDouble() ?? 0,
        'lng': (loc['lng'] as num?)?.toDouble() ?? 0,
      },
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      sockets: List<Map<String, dynamic>>.from(data['sockets'] ?? []),
      pricePerKwh: (data['pricePerKwh'] as num?)?.toDouble(),
      status: data['status'] as String? ?? 'unknown',
      reliabilityScore: (data['reliabilityScore'] as num?)?.toDouble() ?? 3.0,
      supportsReservation: data['supportsReservation'] as bool? ?? false,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      availableCount: data['availableCount'] as int? ?? 0,
      totalSockets: data['totalSockets'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      geohash: data['geohash'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'network': network,
        'location': location,
        'geohash': geohash,
        'address': address,
        'city': city,
        'sockets': sockets,
        if (pricePerKwh != null) 'pricePerKwh': pricePerKwh,
        'status': status,
        'reliabilityScore': reliabilityScore,
        'supportsReservation': supportsReservation,
        'photoUrls': photoUrls,
        'availableCount': availableCount,
        'totalSockets': totalSockets,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  ChargingStationEntity toEntity() => ChargingStationEntity(
        id: id,
        name: name,
        network: StationNetwork.values.firstWhere(
          (n) => n.name == network,
          orElse: () => StationNetwork.zes,
        ),
        location: StationLocation(
          lat: location['lat']!,
          lng: location['lng']!,
        ),
        address: address,
        city: city,
        sockets: sockets.map((s) {
          return ChargingSocketEntity(
            id: s['id'] as String? ?? '',
            type: SocketType.values.firstWhere(
              (t) => t.name == (s['type'] as String? ?? 'ccs2'),
              orElse: () => SocketType.ccs2,
            ),
            powerKw: (s['powerKw'] as num?)?.toDouble() ?? 22,
            status: SocketStatus.values.firstWhere(
              (st) => st.name == (s['status'] as String? ?? 'available'),
              orElse: () => SocketStatus.available,
            ),
            isReservable: s['isReservable'] as bool? ?? false,
          );
        }).toList(),
        pricePerKwh: pricePerKwh,
        status: status,
        reliabilityScore: reliabilityScore,
        supportsReservation: supportsReservation,
        photoUrls: photoUrls,
        availableCount: availableCount,
        totalSockets: totalSockets,
        updatedAt: updatedAt,
      );
}
