import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../domain/entities/station_entity.dart';
import '../providers/map_providers.dart';
import '../widgets/station_filter_sheet.dart';

// Platforma göre doğru GoogleMap implementasyonu yüklenir.
// Web: map_screen_web.dart (JS API index.html'e eklenmiş)
// Native: map_screen_native.dart
import 'map_screen_native.dart' if (dart.library.html) 'map_screen_web.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final stationsAsync = ref.watch(filteredStationsProvider);
    final activeFilters = ref.watch(mapViewNotifierProvider).filters;

    return Scaffold(
      appBar: _buildAppBar(activeFilters, context),
      body: locationAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Konum alınıyor...'),
        error: (e, _) => _LocationErrorView(
          error: e.toString(),
          onRetry: () => ref.invalidate(userLocationProvider),
        ),
        data: (location) {
          // Kullanıcı konumuna göre başlangıç bounds'ını ayarla
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(mapViewNotifierProvider.notifier)
                .initFromLocation(location.latitude, location.longitude);
          });
          return MapView(
            locationLat: location.latitude,
            locationLng: location.longitude,
            stationsAsync: stationsAsync,
            onStationTap: (id) => context.push('/map/station/$id'),
            onBoundsChanged: (bounds) =>
                ref.read(mapViewNotifierProvider.notifier).updateBounds(bounds),
            searchController: _searchController,
            onSearchChanged: (v) =>
                ref.read(mapViewNotifierProvider.notifier).setSearchQuery(v),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(
      StationFiltersEntity activeFilters, BuildContext context) {
    return AppBar(
      title: const Text('Şarj Haritası'),
      actions: [
        if (activeFilters.isActive)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: const Text('Filtre aktif'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                ref
                    .read(mapViewNotifierProvider.notifier)
                    .applyFilters(const StationFiltersEntity());
              },
            ),
          ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.card,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => const StationFilterSheet(),
          ),
        ),
      ],
    );
  }
}

/// Konum izni verilmediğinde veya alınamazken gösterilen view.
class _LocationErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _LocationErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied = error.toLowerCase().contains('denied') ||
        error.toLowerCase().contains('permission');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.location_off_outlined
                  : Icons.wifi_off_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isPermissionDenied ? 'Konum İzni Gerekli' : 'Konum Alınamadı',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPermissionDenied
                  ? 'Yakınındaki şarj istasyonlarını görmek için konum iznine ihtiyaç var.'
                  : 'Lütfen internet bağlantınızı kontrol edin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
