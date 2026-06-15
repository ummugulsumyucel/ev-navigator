import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';

/// Faz 1 MVP — Kullanıcı profili ve istatistikler.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null
                ? null
                : () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(authStateStreamProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (user.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.phone!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 24),
                    StatCard(
                      label: 'Toplam Şarj',
                      value: '${user.stats.totalCharges}',
                      icon: Icons.ev_station,
                      subtitle: 'Tamamlanan oturum sayısı',
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Toplam KM',
                      value: user.stats.totalKm.toStringAsFixed(0),
                      icon: Icons.speed,
                      subtitle: 'Toplam sürüş mesafesi',
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Toplam Tasarruf',
                      value: '₺${user.stats.totalSavingsTl.toStringAsFixed(0)}',
                      icon: Icons.savings,
                      subtitle: 'EV kullanım tasarrufu',
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      onTap: () => context.push('/vehicles'),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.directions_car),
                        title: Text('Araçlarım'),
                        subtitle: Text('Birden fazla araç yönet'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      onTap: () => context.push('/battery'),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.battery_charging_full),
                        title: Text('Batarya Sağlığı'),
                        subtitle: Text('SOH, SOC, tüketim grafikleri'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      onTap: () => context.push('/cost'),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calculate),
                        title: Text('Maliyet Hesaplayıcı'),
                        subtitle: Text('EV vs benzin/dizel karşılaştırması'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      onTap: () => context.push('/service'),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.build),
                        title: Text('Servis & Destek'),
                        subtitle: Text('Randevu talebi, navigasyon'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      onTap: () => context.go('/planner'),
                      child: const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.route),
                        title: Text('Güzergah Planlayıcı'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FavoriteStationsSection(userId: user.uid),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hesap Bilgileri',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'E-posta doğrulama',
                            value: user.emailVerified ? 'Doğrulandı' : 'Bekliyor',
                            icon: user.emailVerified
                                ? Icons.verified
                                : Icons.mark_email_unread,
                          ),
                          _InfoRow(
                            label: 'Profil durumu',
                            value: user.profileCompleted
                                ? 'Tamamlandı'
                                : 'Eksik',
                            icon: Icons.person,
                          ),
                          _InfoRow(
                            label: 'Üyelik',
                            value: user.createdAt != null
                                ? _formatDate(user.createdAt!)
                                : '—',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _FavoriteStationsSection extends ConsumerWidget {
  const _FavoriteStationsSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesStream = ref
        .watch(stationRepositoryProvider)
        .watchFavoriteStationIds(userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favori İstasyonlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<String>>(
          stream: favoritesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final ids = snapshot.data!;
            if (ids.isEmpty) {
              return const AppCard(
                child: Text(
                  'Henüz favori istasyon eklemediniz. Haritadan istasyon detayına giderek favorilere ekleyebilirsiniz.',
                ),
              );
            }
            return Column(
              children: ids.map((id) {
                return FutureBuilder(
                  future: ref.read(stationRepositoryProvider).getStation(id),
                  builder: (context, stationSnap) {
                    if (!stationSnap.hasData || stationSnap.data == null) {
                      return const SizedBox.shrink();
                    }
                    final station = stationSnap.data!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        onTap: () => context.push('/map/station/$id'),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          title: Text(station.name),
                          subtitle: Text(station.network.displayName),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
