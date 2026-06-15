import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/station_entity.dart';
import '../providers/map_providers.dart';

class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationStream =
        ref.watch(stationRepositoryProvider).watchStation(stationId);
    final user = ref.watch(currentUserProvider);
    final favoriteAsync = ref.watch(isFavoriteProvider(stationId));

    return Scaffold(
      appBar: AppBar(title: const Text('İstasyon Detayı')),
      body: StreamBuilder<ChargingStationEntity>(
        stream: stationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const AppErrorView(message: 'İstasyon bulunamadı');
          }
          final station = snapshot.data!;
          final isFavorite = favoriteAsync.valueOrNull ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (station.photoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: AppRadius.cardBorder,
                    child: CachedNetworkImage(
                      imageUrl: station.photoUrls.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerCard(height: 200),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppColors.cardElevated,
                        child: const Icon(Icons.ev_station, size: 64),
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    height: 160,
                    child: Center(
                      child: Icon(Icons.ev_station, size: 64),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  station.network.displayName,
                  style: const TextStyle(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  station.address,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Müsait',
                        value:
                            '${station.availableCount}/${station.totalSockets}',
                        icon: Icons.ev_station,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Güvenilirlik',
                        value: station.reliabilityScore.toStringAsFixed(1),
                        icon: Icons.star,
                        color: station.isLowReliability
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (station.pricePerKwh != null)
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.payments, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          '₺${station.pricePerKwh!.toStringAsFixed(2)} / kWh',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Soketler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                ...station.sockets.map(
                  (s) => ListTile(
                    title: Text(_socketLabel(s.type)),
                    subtitle: Text('${s.powerKw.toInt()} kW'),
                    trailing: Chip(
                      label: Text(_statusLabel(s.status)),
                      backgroundColor: s.status == SocketStatus.available
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.cardElevated,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: user == null
                            ? null
                            : () async {
                                await ref
                                    .read(stationRepositoryProvider)
                                    .toggleFavorite(user.uid, station.id);
                                ref.invalidate(isFavoriteProvider(stationId));
                              },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        label: Text(isFavorite ? 'Favoride' : 'Favori'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDirections(station),
                        icon: const Icon(Icons.directions),
                        label: const Text('Yol Tarifi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Yorumlar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (user != null)
                      TextButton(
                        onPressed: () => _showReviewDialog(context, ref, user),
                        child: const Text('Yorum Yaz'),
                      ),
                  ],
                ),
                _ReviewsList(stationId: stationId),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDirections(ChargingStationEntity station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${station.location.lat},${station.location.lng}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    final commentController = TextEditingController();
    var rating = 4.0;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yorum Yaz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 8,
              label: rating.toStringAsFixed(1),
              onChanged: (v) => rating = v,
            ),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Deneyiminizi paylaşın...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) return;
              final review = StationReviewEntity(
                id: const Uuid().v4(),
                stationId: stationId,
                userId: user.uid,
                userName: user.displayName,
                rating: rating,
                comment: commentController.text.trim(),
                photoUrls: const [],
                createdAt: DateTime.now(),
              );
              await ref.read(stationRepositoryProvider).addReview(review);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    commentController.dispose();
  }

  String _socketLabel(SocketType type) => switch (type) {
        SocketType.ccs2 => 'CCS2',
        SocketType.chademo => 'CHAdeMO',
        SocketType.acType2 => 'AC Type 2',
        SocketType.tesla => 'Tesla',
      };

  String _statusLabel(SocketStatus status) => switch (status) {
        SocketStatus.available => 'Müsait',
        SocketStatus.occupied => 'Dolu',
        SocketStatus.faulted => 'Arızalı',
      };
}

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<StationReviewEntity>>(
      future: ref.read(stationRepositoryProvider).getReviews(stationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ShimmerCard(height: 80);
        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Henüz yorum yok',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        return Column(
          children: reviews
              .map(
                (r) => AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.userName),
                    subtitle: Text(r.comment),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(r.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
