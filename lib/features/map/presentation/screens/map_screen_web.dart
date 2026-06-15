import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../domain/entities/station_entity.dart';

/// Web platformu için Google Maps implementasyonu.
/// google_maps_flutter web desteğini kullanır.
/// [MapScreen] tarafından conditional import ile yüklenir.
class MapView extends ConsumerStatefulWidget {
  const MapView({
    super.key,
    required this.locationLat,
    required this.locationLng,
    required this.stationsAsync,
    required this.onStationTap,
    required this.onBoundsChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  final double locationLat;
  final double locationLng;
  final AsyncValue<List<ChargingStationEntity>> stationsAsync;
  final void Function(String stationId) onStationTap;
  final void Function(LatLngBounds bounds) onBoundsChanged;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(39.9334, 32.8597), // Türkiye merkezi
    zoom: 6,
  );

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stationsAsync != widget.stationsAsync) {
      _buildMarkers();
    }
  }

  void _buildMarkers() {
    final stations = widget.stationsAsync.valueOrNull ?? [];
    final newMarkers = stations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.location.lat, station.location.lng),
        infoWindow: InfoWindow(
          title: station.name,
          snippet:
              '${station.availableCount}/${station.totalSockets} müsait • ${station.network.displayName}',
          onTap: () => widget.onStationTap(station.id),
        ),
        icon: _markerIcon(station),
        onTap: () => widget.onStationTap(station.id),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    }
  }

  BitmapDescriptor _markerIcon(ChargingStationEntity station) {
    if (station.availableCount == 0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    if (station.isLowReliability) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.locationLat, widget.locationLng),
          zoom: 13,
        ),
      ),
    );
    _buildMarkers();
  }

  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;
    final bounds = await _mapController!.getVisibleRegion();
    widget.onBoundsChanged(bounds);
    _buildMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: _defaultCamera,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onCameraIdle: _onCameraIdle,
        ),
        // Arama çubuğu
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _SearchBar(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
          ),
        ),
        // Konum butonu
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.card,
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(widget.locationLat, widget.locationLng),
                    zoom: 14,
                  ),
                ),
              );
            },
            child: const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
        // İstasyon yükleniyor göstergesi
        if (widget.stationsAsync.isLoading)
          const Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: AppLoadingIndicator(message: 'İstasyonlar yükleniyor...'),
            ),
          ),
        // İstasyon hata göstergesi
        if (widget.stationsAsync.hasError)
          Positioned(
            top: 70,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                borderRadius: AppRadius.cardBorder,
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İstasyonlar yüklenemedi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // İstasyon sayısı göstergesi
        if (widget.stationsAsync.hasValue)
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${widget.stationsAsync.valueOrNull?.length ?? 0} istasyon',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'İstasyon ara...',
          hintStyle: TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
