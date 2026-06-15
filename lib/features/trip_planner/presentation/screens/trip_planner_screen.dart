import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/trip_entity.dart';
import '../providers/trip_providers.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _originController = TextEditingController(text: 'İstanbul');
  final _destController = TextEditingController(text: 'Ankara');
  VehiclePreset _vehicle = VehiclePreset.presets.first;
  double _startSoc = 80;
  TripStrategy _strategy = TripStrategy.balanced;

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<TripLocation?> _geocode(String query) async {
    try {
      final locations = await locationFromAddress('$query, Türkiye');
      if (locations.isEmpty) return null;
      return TripLocation(
        name: query,
        lat: locations.first.latitude,
        lng: locations.first.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _planTrip() async {
    final origin = await _geocode(_originController.text.trim());
    final dest = await _geocode(_destController.text.trim());

    if (origin == null || dest == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum bulunamadı. Şehir adı girin.')),
        );
      }
      return;
    }

    await ref.read(tripPlannerControllerProvider.notifier).plan(
          origin: origin,
          destination: dest,
          vehicle: _vehicle,
          startSoc: _startSoc,
          strategy: _strategy,
        );
  }

  Future<void> _saveTrip(TripPlanResult result) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final origin = await _geocode(_originController.text.trim());
    final dest = await _geocode(_destController.text.trim());
    if (origin == null || dest == null) return;

    await ref.read(tripPlannerControllerProvider.notifier).saveCurrentTrip(
          result: result,
          origin: origin,
          destination: dest,
          vehicle: _vehicle,
          startSoc: _startSoc,
          strategy: _strategy,
          userId: user.uid,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota kaydedildi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(tripPlannerControllerProvider);
    final tripsAsync = ref.watch(userTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Güzergah Planlayıcı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Başlangıç',
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destController,
              decoration: const InputDecoration(
                labelText: 'Varış',
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<VehiclePreset>(
              value: _vehicle,
              decoration: const InputDecoration(
                labelText: 'Araç Modeli',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: VehiclePreset.presets
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _vehicle = v!),
            ),
            const SizedBox(height: 16),
            Text('Batarya: %${_startSoc.toInt()}'),
            Slider(
              value: _startSoc,
              min: 10,
              max: 100,
              divisions: 18,
              label: '%${_startSoc.toInt()}',
              onChanged: (v) => setState(() => _startSoc = v),
            ),
            const SizedBox(height: 8),
            const Text(
              'Strateji',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Wrap(
              spacing: 8,
              children: TripStrategy.values.map((s) {
                return ChoiceChip(
                  label: Text(_strategyLabel(s)),
                  selected: _strategy == s,
                  onSelected: (_) => setState(() => _strategy = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: planState.isLoading ? null : _planTrip,
              child: planState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Rota Oluştur'),
            ),
            const SizedBox(height: 24),
            planState.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return _PlanResultCard(
                  result: result,
                  onSave: () => _saveTrip(result),
                );
              },
              loading: () => const AppLoadingIndicator(message: 'Rota hesaplanıyor...'),
              error: (e, _) => AppErrorView(message: e.toString()),
            ),
            const SizedBox(height: 24),
            const Text(
              'Geçmiş Rotalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return const AppCard(
                    child: Text('Henüz kaydedilmiş rota yok'),
                  );
                }
                return Column(
                  children: trips
                      .map(
                        (t) => AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.route, color: AppColors.primary),
                            title: Text('${t.origin.name} → ${t.destination.name}'),
                            subtitle: Text(
                              '${t.distanceKm.toStringAsFixed(0)} km • '
                              '${t.totalMinutes} dk • '
                              '₺${t.totalCostTl.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const ShimmerCard(),
              error: (e, _) => Text('Hata: $e'),
            ),
          ],
        ),
      ),
    );
  }

  String _strategyLabel(TripStrategy s) => switch (s) {
        TripStrategy.fastest => 'En Hızlı',
        TripStrategy.cheapest => 'En Ucuz',
        TripStrategy.balanced => 'Dengeli',
        TripStrategy.safest => 'En Güvenli',
      };
}

class _PlanResultCard extends StatelessWidget {
  const _PlanResultCard({required this.result, required this.onSave});

  final TripPlanResult result;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rota Özeti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _Row(label: 'Mesafe', value: '${result.distanceKm.toStringAsFixed(0)} km'),
          _Row(label: 'Sürüş', value: '${result.driveMinutes} dk'),
          _Row(label: 'Şarj', value: '${result.chargeMinutes} dk'),
          _Row(
            label: 'Toplam Maliyet',
            value: '₺${result.totalCostTl.toStringAsFixed(0)}',
            highlight: true,
          ),
          _Row(
            label: 'Mevcut Menzil',
            value: '${result.availableRangeKm.toStringAsFixed(0)} km',
          ),
          if (result.chargingStops.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Şarj Durakları',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...result.chargingStops.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.ev_station, color: AppColors.primary),
                title: Text(s.stationName),
                subtitle: Text('${s.chargeMinutes} dk • ₺${s.costTl.toStringAsFixed(0)}'),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Tek şarj yeterli — durak gerekmez.',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Rotayı Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
