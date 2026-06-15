class StationLocation {
  const StationLocation({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

enum SocketType { ccs2, chademo, acType2, tesla }

enum SocketStatus { available, occupied, faulted }

enum StationNetwork {
  zes,
  esarj,
  trugo,
  wat,
  tesla,
  shell;

  String get displayName => switch (this) {
        StationNetwork.zes => 'ZES',
        StationNetwork.esarj => 'Eşarj',
        StationNetwork.trugo => 'Trugo',
        StationNetwork.wat => 'WAT',
        StationNetwork.tesla => 'Tesla',
        StationNetwork.shell => 'Shell Recharge',
      };
}

class ChargingSocketEntity {
  const ChargingSocketEntity({
    required this.id,
    required this.type,
    required this.powerKw,
    required this.status,
    this.isReservable = false,
  });

  final String id;
  final SocketType type;
  final double powerKw;
  final SocketStatus status;
  final bool isReservable;
}

class ChargingStationEntity {
  const ChargingStationEntity({
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
  });

  final String id;
  final String name;
  final StationNetwork network;
  final StationLocation location;
  final String address;
  final String city;
  final List<ChargingSocketEntity> sockets;
  final double? pricePerKwh;
  final String status;
  final double reliabilityScore;
  final bool supportsReservation;
  final List<String> photoUrls;
  final int availableCount;
  final int totalSockets;
  final DateTime updatedAt;

  bool get isLowReliability => reliabilityScore < 2.5;
}

class StationReviewEntity {
  const StationReviewEntity({
    required this.id,
    required this.stationId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final List<String> photoUrls;
  final DateTime createdAt;
}

class StationFiltersEntity {
  const StationFiltersEntity({
    this.socketTypes = const {},
    this.networks = const {},
    this.minPowerKw,
    this.maxPrice,
    this.onlyAvailable = false,
    this.minReliability,
  });

  final Set<SocketType> socketTypes;
  final Set<StationNetwork> networks;
  final double? minPowerKw;
  final double? maxPrice;
  final bool onlyAvailable;
  final double? minReliability;

  bool get isActive =>
      socketTypes.isNotEmpty ||
      networks.isNotEmpty ||
      minPowerKw != null ||
      maxPrice != null ||
      onlyAvailable ||
      minReliability != null;
}
