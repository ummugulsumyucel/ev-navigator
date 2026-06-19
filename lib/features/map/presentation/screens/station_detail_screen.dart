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
    final stationAsync = ref.watch(stationDetailProvider(stationId));
    final user = ref.watch(currentUserProvider);
    final favoriteAsync = ref.watch(isFavoriteProvider(stationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: stationAsync.when(
        loading: () => const Scaffold(
          appBar: null,
          body: AppLoadingIndicator(message: 'İstasyon yükleniyor...'),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('İstasyon Detayı')),
          body: AppErrorView(
            message: 'İstasyon yüklenemedi: $e',
            onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
          ),
        ),
        data: (station) {
          if (station == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('İstasyon Detayı')),
              body: const AppErrorView(message: 'İstasyon bulunamadı'),
            );
          }
          return _StationDetailBody(
            station: station,
            stationId: stationId,
            user: user,
            isFavorite: favoriteAsync.valueOrNull ?? false,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ana gövde
// ---------------------------------------------------------------------------

class _StationDetailBody extends ConsumerWidget {
  const _StationDetailBody({
    required this.station,
    required this.stationId,
    required this.user,
    required this.isFavorite,
  });

  final ChargingStationEntity station;
  final String stationId;
  final UserEntity? user;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableRatio = station.totalSockets > 0
        ? station.availableCount / station.totalSockets
        : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar / Hero banner ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: const BackButton(),
            title: Text(
              station.name,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Favori butonu app bar'da
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppColors.textPrimary,
                ),
                onPressed: user == null
                    ? null
                    : () async {
                        await ref
                            .read(stationRepositoryProvider)
                            .toggleFavorite(user!.uid, station.id);
                        ref.invalidate(isFavoriteProvider(stationId));
                      },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _StationHero(station: station),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ağ + şehir + durum ────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          station.network.displayName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          station.city,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _StatusBadge(status: station.status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Adres ─────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.textMuted, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          station.address,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── İstatistik kartları ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.ev_station,
                          label: 'Müsait Soket',
                          value:
                              '${station.availableCount} / ${station.totalSockets}',
                          color: station.availableCount > 0
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.star_rounded,
                          label: 'Güvenilirlik',
                          value:
                              '${station.reliabilityScore.toStringAsFixed(1)} / 5',
                          color: station.isLowReliability
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                      if (station.pricePerKwh != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.bolt,
                            label: 'Fiyat / kWh',
                            value:
                                '₺${station.pricePerKwh!.toStringAsFixed(2)}',
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Müsaitlik progress bar ─────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Doluluk Oranı',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            Text(
                              '%${((1 - availableRatio) * 100).toInt()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1 - availableRatio,
                            minHeight: 8,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              availableRatio > 0.5
                                  ? AppColors.primary
                                  : availableRatio > 0
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Soketler ──────────────────────────────────────────
                  const Text(
                    'Şarj Soketleri',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (station.sockets.isEmpty)
                    const Text(
                      'Soket bilgisi mevcut değil',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...station.sockets.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _socketColor(s.type)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.power,
                                  color: _socketColor(s.type),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _socketLabel(s.type),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${s.powerKw.toInt()} kW',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _SocketStatusChip(status: s.status),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Özellikler ────────────────────────────────────────
                  const Text(
                    'Özellikler',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (station.supportsReservation)
                        const _FeatureChip(
                            icon: Icons.calendar_today, label: 'Rezervasyon'),
                      _FeatureChip(
                        icon: station.availableCount > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        label: station.availableCount > 0 ? 'Müsait' : 'Dolu',
                        color: station.availableCount > 0
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                      _FeatureChip(
                        icon: Icons.bolt,
                        label:
                            '${station.sockets.isNotEmpty ? station.sockets.map((s) => s.powerKw).reduce((a, b) => a > b ? a : b).toInt() : 0} kW maks.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Eylem butonları ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: user == null
                              ? null
                              : () async {
                                  await ref
                                      .read(stationRepositoryProvider)
                                      .toggleFavorite(user!.uid, station.id);
                                  ref.invalidate(isFavoriteProvider(stationId));
                                },
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                            size: 18,
                          ),
                          label: Text(isFavorite ? 'Favoride' : 'Favori Ekle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openDirections(station),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Yol Tarifi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Yorumlar ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yorumlar',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      if (user != null)
                        TextButton.icon(
                          onPressed: () =>
                              _showReviewDialog(context, ref, user!),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Yorum Yaz'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ReviewsList(stationId: stationId),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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
    double rating = 4.0;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yorum Yaz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Puan:',
                  style: TextStyle(color: AppColors.textSecondary)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: rating,
                      min: 1,
                      max: 5,
                      divisions: 8,
                      label: rating.toStringAsFixed(1),
                      onChanged: (v) => setDialogState(() => rating = v),
                    ),
                  ),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
      ),
    );
    commentController.dispose();
  }

  Color _socketColor(SocketType type) => switch (type) {
        SocketType.ccs2 => const Color(0xFF3B82F6),
        SocketType.chademo => const Color(0xFFF59E0B),
        SocketType.acType2 => AppColors.primary,
        SocketType.tesla => const Color(0xFFEF4444),
      };

  String _socketLabel(SocketType type) => switch (type) {
        SocketType.ccs2 => 'CCS2 (DC Hızlı)',
        SocketType.chademo => 'CHAdeMO (DC)',
        SocketType.acType2 => 'AC Type 2',
        SocketType.tesla => 'Tesla Supercharger',
      };
}

// ---------------------------------------------------------------------------
// Yardımcı widget'lar
// ---------------------------------------------------------------------------

class _StationHero extends StatelessWidget {
  const _StationHero({required this.station});
  final ChargingStationEntity station;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1115), Color(0xFF1B1E25)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48), // app bar alanı için
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ev_station,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              station.network.displayName,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.primary : AppColors.error)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.circle : Icons.cancel,
            size: 8,
            color: isActive ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Aktif' : 'Pasif',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SocketStatusChip extends StatelessWidget {
  const _SocketStatusChip({required this.status});
  final SocketStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketStatus.available => ('Müsait', AppColors.primary),
      SocketStatus.occupied => ('Dolu', AppColors.warning),
      SocketStatus.faulted => ('Arızalı', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yorumlar listesi
// ---------------------------------------------------------------------------

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock istasyon yorumları
    final mockReviews = _getMockReviews(stationId);

    return FutureBuilder<List<StationReviewEntity>>(
      future: ref.read(stationRepositoryProvider).getReviews(stationId),
      builder: (context, snapshot) {
        final reviews = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!
            : mockReviews;

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Henüz yorum yok. İlk yorumu siz yapın!',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Column(
          children: reviews.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        r.userName.isNotEmpty
                            ? r.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < r.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.comment,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<StationReviewEntity> _getMockReviews(String stationId) {
    final now = DateTime.now();
    return switch (stationId) {
      'ms_ist_1' => [
          StationReviewEntity(
            id: 'r1',
            stationId: stationId,
            userId: 'u1',
            userName: 'Ahmet K.',
            rating: 5.0,
            comment: 'Hızlı şarj, temiz alan. Her zaman müsait bulurum.',
            photoUrls: const [],
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          StationReviewEntity(
            id: 'r2',
            stationId: stationId,
            userId: 'u2',
            userName: 'Selin M.',
            rating: 4.0,
            comment: 'İyi konum, AVM içinde rahat bekleyebiliyorsunuz.',
            photoUrls: const [],
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      'ms_ist_5' => [
          StationReviewEntity(
            id: 'r3',
            stationId: stationId,
            userId: 'u3',
            userName: 'Emre T.',
            rating: 5.0,
            comment:
                'Tesla Supercharger her zamanki gibi mükemmel. 20 dk\'da %80.',
            photoUrls: const [],
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      _ => [
          StationReviewEntity(
            id: 'r_default',
            stationId: stationId,
            userId: 'u0',
            userName: 'EV Navigator',
            rating: 4.0,
            comment: 'Bu istasyon hakkında bilgi paylaşmak için yorum ekleyin.',
            photoUrls: const [],
            createdAt: now.subtract(const Duration(days: 10)),
          ),
        ],
    };
  }
}
