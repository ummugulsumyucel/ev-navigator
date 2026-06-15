import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/station_entity.dart';

class StationMarkerBuilder {
  static Set<Marker> build(
    List<ChargingStationEntity> stations, {
    void Function(String stationId)? onTap,
  }) {
    return stations.map((station) {
      final hue = _networkHue(station.network);
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.location.lat, station.location.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: onTap != null ? () => onTap(station.id) : null,
        infoWindow: InfoWindow(
          title: station.name,
          snippet:
              '${station.availableCount}/${station.totalSockets} müsait • '
              '${station.pricePerKwh != null ? '₺${station.pricePerKwh!.toStringAsFixed(2)}/kWh' : 'Fiyat bilinmiyor'}',
        ),
      );
    }).toSet();
  }

  static double _networkHue(StationNetwork network) {
    return switch (network) {
      StationNetwork.zes => BitmapDescriptor.hueGreen,
      StationNetwork.esarj => BitmapDescriptor.hueBlue,
      StationNetwork.trugo => BitmapDescriptor.hueOrange,
      StationNetwork.tesla => BitmapDescriptor.hueRed,
      StationNetwork.wat => BitmapDescriptor.hueCyan,
      StationNetwork.shell => BitmapDescriptor.hueYellow,
    };
  }
}
