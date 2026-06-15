import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nearbyAsync = ref.watch(nearbyStationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EV Navigator'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
              return Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nearbyStationsProvider);
          ref.invalidate(authStateStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba, ${user?.displayName ?? 'Sürücü'} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    label: 'Toplam Şarj',
                    value: '${user?.stats.totalCharges ?? 0}',
                    icon: Icons.ev_station,
                    subtitle: 'Tamamlanan oturum',
                    onTap: () => context.go('/profile'),
                  ),
                  StatCard(
                    label: 'Toplam KM',
                    value: user?.stats.totalKm.toStringAsFixed(0) ?? '0',
                    icon: Icons.speed,
                    subtitle: 'Sürüş mesafesi',
                    onTap: () => context.go('/profile'),
                  ),
                  StatCard(
                    label: 'Aylık Tasarruf',
                    value:
                        '₺${user?.stats.totalSavingsTl.toStringAsFixed(0) ?? '0'}',
                    icon: Icons.savings_outlined,
                    subtitle: 'EV vs benzin',
                    onTap: () => context.push('/cost'),
                  ),
                  StatCard(
                    label: 'Batarya SOC',
                    value: '%78',
                    icon: Icons.battery_5_bar,
                    subtitle: 'Sağlık & menzil',
                    onTap: () => context.push('/battery'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Hızlı Erişim',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _QuickAction(
                      icon: Icons.route,
                      label: 'Planlayıcı',
                      onTap: () => context.go('/planner'),
                    ),
                    _QuickAction(
                      icon: Icons.map,
                      label: 'Harita',
                      onTap: () => context.go('/map'),
                    ),
                    _QuickAction(
                      icon: Icons.calculate,
                      label: 'Maliyet',
                      onTap: () => context.push('/cost'),
                    ),
                    _QuickAction(
                      icon: Icons.build,
                      label: 'Servis',
                      onTap: () => context.push('/service'),
                    ),
                    _QuickAction(
                      icon: Icons.forum,
                      label: 'Topluluk',
                      onTap: () => context.go('/community'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yakındaki İstasyonlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.go('/map'),
                    child: const Text('Haritada Gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              nearbyAsync.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => AppErrorView(message: e.toString()),
                data: (stations) {
                  if (stations.isEmpty) {
                    return AppCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.ev_station_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Yakında istasyon bulunamadı.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/map'),
                            icon: const Icon(Icons.map),
                            label: const Text('Haritayı Aç'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: stations.take(5).map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => context.push('/map/station/${s.id}'),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.ev_station,
                              color: AppColors.primary,
                            ),
                            title: Text(s.name),
                            subtitle: Text(
                              '${s.availableCount}/${s.totalSockets} müsait • ${s.network.displayName}',
                            ),
                            trailing: s.pricePerKwh != null
                                ? Text(
                                    '₺${s.pricePerKwh!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Son Haberler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _NewsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Ink(
          width: 88,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .watch(firestoreProvider)
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ShimmerCard();
        if (snapshot.data!.docs.isEmpty) {
          return const AppCard(child: Text('Henüz haber yok'));
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.newspaper, color: AppColors.secondary),
                  title: Text(data['title'] as String? ?? ''),
                  subtitle: Text(data['summary'] as String? ?? ''),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
