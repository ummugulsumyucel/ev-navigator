import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/service_providers.dart';

class ServiceMapScreen extends ConsumerStatefulWidget {
  const ServiceMapScreen({super.key});

  @override
  ConsumerState<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends ConsumerState<ServiceMapScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(filteredServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Servis & Destek')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(serviceSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Servis veya marka ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(serviceSearchProvider.notifier).state = '';
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppErrorView(message: e.toString()),
              data: (services) {
                if (services.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Servis verisi yok. Firebase services koleksiyonuna veri ekleyin.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final authorized =
                    services.where((s) => s.isAuthorized).toList();
                final independent =
                    services.where((s) => !s.isAuthorized).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (authorized.isNotEmpty) ...[
                      const _SectionTitle(
                        title: 'Yetkili Servisler',
                        icon: Icons.verified,
                      ),
                      ...authorized.map((s) => _ServiceCard(service: s)),
                    ],
                    if (independent.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _SectionTitle(
                        title: 'Özel Servisler',
                        icon: Icons.build,
                      ),
                      ...independent.map((s) => _ServiceCard(service: s)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});

  final ServiceEntity service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (service.isAuthorized)
                  const Icon(Icons.verified, color: AppColors.primary, size: 18),
              ],
            ),
            Text(
              service.brand,
              style: const TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              service.address,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (service.serviceTypes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: service.serviceTypes
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${service.rating.toStringAsFixed(1)}'),
                Text(
                  ' (${service.reviewCount})',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  '~${service.avgWaitDays} gün',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${service.phone}')),
                  icon: const Icon(Icons.phone),
                  label: const Text('Ara'),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination='
                      '${service.location.lat},${service.location.lng}',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigasyon'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _bookAppointment(context, ref),
                  child: const Text('Randevu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookAppointment(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(serviceRepositoryProvider).createAppointment(
          userId: user.uid,
          serviceId: service.id,
          serviceName: service.name,
          serviceType: service.serviceTypes.isNotEmpty
              ? service.serviceTypes.first
              : 'Periyodik Bakım',
          date: DateTime.now().add(Duration(days: service.avgWaitDays)),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu talebi gönderildi')),
      );
    }
  }
}
