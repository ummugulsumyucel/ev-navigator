import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../domain/entities/station_entity.dart';
import '../providers/map_providers.dart';
import '../widgets/station_filter_sheet.dart';

import 'map_screen_native.dart' if (dart.library.html) 'map_screen_web.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(mapViewNotifierProvider.notifier).setSearchQuery('');
    _searchFocusNode.unfocus();
    setState(() => _searchFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);
    final stationsAsync = ref.watch(filteredStationsProvider);
    final activeFilters = ref.watch(mapViewNotifierProvider).filters;
    final searchQuery = ref.watch(mapViewNotifierProvider).searchQuery;
    final isSearching = searchQuery.isNotEmpty || _searchFocused;

    return Scaffold(
      appBar: _buildAppBar(activeFilters, context),
      body: locationAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Konum alınıyor...'),
        error: (e, _) => _LocationErrorView(
          error: e.toString(),
          onRetry: () => ref.invalidate(userLocationProvider),
        ),
        data: (location) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(mapViewNotifierProvider.notifier)
                .initFromLocation(location.latitude, location.longitude);
          });

          return Stack(
            children: [
              // Harita — her zaman arkada
              MapView(
                locationLat: location.latitude,
                locationLng: location.longitude,
                stationsAsync: stationsAsync,
                onStationTap: (id) => context.push('/map/station/$id'),
                onBoundsChanged: (bounds) => ref
                    .read(mapViewNotifierProvider.notifier)
                    .updateBounds(bounds),
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchChanged: (v) {
                  ref.read(mapViewNotifierProvider.notifier).setSearchQuery(v);
                  setState(() {});
                },
              ),
              // Arama sonuç listesi — arama aktifken haritanın üstüne geliyor
              if (isSearching && searchQuery.isNotEmpty)
                _SearchResultsList(
                  stationsAsync: stationsAsync,
                  onTap: (id) {
                    _clearSearch();
                    context.push('/map/station/$id');
                  },
                ),
            ],
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

// ---------------------------------------------------------------------------
// Arama sonuç listesi overlay
// ---------------------------------------------------------------------------

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.stationsAsync,
    required this.onTap,
  });

  final AsyncValue<List<ChargingStationEntity>> stationsAsync;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 68,
      left: 12,
      right: 12,
      bottom: 16,
      child: Material(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        elevation: 8,
        child: ClipRRect(
          borderRadius: AppRadius.cardBorder,
          child: stationsAsync.when(
            loading: () => const Center(
              child: AppLoadingIndicator(message: 'Aranıyor...'),
            ),
            error: (e, _) => const Center(
              child: Text('Arama başarısız'),
            ),
            data: (stations) {
              if (stations.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'İstasyon bulunamadı',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Sonuç sayısı başlığı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Text(
                      '${stations.length} istasyon bulundu',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: stations.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 0,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, i) {
                        final s = stations[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: s.availableCount > 0
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.ev_station,
                              size: 18,
                              color: s.availableCount > 0
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${s.network.displayName} • ${s.city}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${s.availableCount}/${s.totalSockets}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: s.availableCount > 0
                                      ? AppColors.primary
                                      : AppColors.error,
                                ),
                              ),
                              if (s.pricePerKwh != null)
                                Text(
                                  '₺${s.pricePerKwh!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => onTap(s.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ) as Widget;
  }
}

// ---------------------------------------------------------------------------
// Konum izni / hata ekranı
// ---------------------------------------------------------------------------

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
