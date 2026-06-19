import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/trip_entity.dart';
import '../providers/trip_providers.dart';

// ---------------------------------------------------------------------------
// Türkiye'nin büyük şehirleri — koordinatlarıyla birlikte
// ---------------------------------------------------------------------------
class _City {
  const _City(this.name, this.lat, this.lng);
  final String name;
  final double lat;
  final double lng;
}

const _turkishCities = [
  _City('İstanbul', 41.0082, 28.9784),
  _City('Ankara', 39.9334, 32.8597),
  _City('İzmir', 38.4189, 27.1287),
  _City('Bursa', 40.1885, 29.0610),
  _City('Antalya', 36.8969, 30.7133),
  _City('Adana', 37.0000, 35.3213),
  _City('Konya', 37.8714, 32.4846),
  _City('Gaziantep', 37.0662, 37.3833),
  _City('Mersin', 36.8000, 34.6333),
  _City('Kayseri', 38.7312, 35.4787),
  _City('Eskişehir', 39.7767, 30.5206),
  _City('Samsun', 41.2867, 36.3300),
  _City('Trabzon', 41.0015, 39.7178),
  _City('Diyarbakır', 37.9144, 40.2306),
  _City('Denizli', 37.7765, 29.0864),
  _City('Sakarya', 40.7731, 30.3948),
  _City('Kocaeli', 40.8533, 29.8815),
  _City('Hatay', 36.4018, 36.3498),
  _City('Malatya', 38.3552, 38.3095),
  _City('Kahramanmaraş', 37.5858, 36.9371),
  _City('Erzurum', 39.9043, 41.2679),
  _City('Van', 38.4891, 43.4089),
  _City('Tekirdağ', 40.9781, 27.5115),
  _City('Manisa', 38.6191, 27.4289),
  _City('Balıkesir', 39.6484, 27.8826),
  _City('Muğla', 37.2153, 28.3636),
  _City('Edirne', 41.6818, 26.5623),
  _City('Zonguldak', 41.4564, 31.7987),
  _City('Çanakkale', 40.1553, 26.4142),
  _City('Aydın', 37.8444, 27.8458),
];

// ---------------------------------------------------------------------------
// Yardımcı: Haversine mesafesi (km)
// ---------------------------------------------------------------------------
double _haversineKm(_City a, _City b) {
  const r = 6371.0;
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.lat)) *
          math.cos(_rad(b.lat)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return r * 2 * math.asin(math.sqrt(x));
}

double _rad(double deg) => deg * math.pi / 180;

// ---------------------------------------------------------------------------
// Offline rota hesaplama (Directions API yokken)
// ---------------------------------------------------------------------------
TripPlanResult _calculateOffline({
  required _City origin,
  required _City destination,
  required VehiclePreset vehicle,
  required double startSoc,
  required TripStrategy strategy,
}) {
  final distKm = _haversineKm(origin, destination) * 1.15; // yol faktörü
  const avgSpeedKmh = 90.0;
  final driveMinutes = (distKm / avgSpeedKmh * 60).ceil();

  final availableRangeKm = vehicle.wltpRangeKm * (startSoc / 100) * 0.85;
  final electricityPrice = strategy == TripStrategy.cheapest ? 8.5 : 11.5;

  if (distKm <= availableRangeKm * 0.85) {
    // Şarj durağına gerek yok
    return TripPlanResult(
      distanceKm: distKm,
      driveMinutes: driveMinutes,
      chargeMinutes: 0,
      totalCostTl: 0,
      chargingStops: const [],
      availableRangeKm: availableRangeKm,
    );
  }

  // Kaç durak gerekiyor?
  final stopsNeeded = (distKm / (availableRangeKm * 0.75)).ceil() - 1;
  final clampedStops = stopsNeeded.clamp(1, 4);

  final chargeKwhPerStop = vehicle.batteryKwh * (0.80 - 0.15); // %15'ten %80'e
  final powerKw = strategy == TripStrategy.fastest ? 150.0 : 50.0;
  final chargeMinPerStop =
      (chargeKwhPerStop / powerKw * 60).ceil().clamp(20, 60);

  final stops = List.generate(clampedStops, (i) {
    final fraction = (i + 1) / (clampedStops + 1);
    final stopLat = origin.lat + (destination.lat - origin.lat) * fraction;
    final stopLng = origin.lng + (destination.lng - origin.lng) * fraction;
    final costTl = chargeKwhPerStop * electricityPrice;
    return ChargingStopEntity(
      stationId: 'offline_stop_$i',
      stationName: _stopName(origin, destination, fraction),
      chargeMinutes: chargeMinPerStop,
      costTl: costTl,
      lat: stopLat,
      lng: stopLng,
    );
  });

  final totalCost = stops.fold(0.0, (sum, s) => sum + s.costTl);
  final totalChargeMin = stops.fold(0, (sum, s) => sum + s.chargeMinutes);

  return TripPlanResult(
    distanceKm: distKm,
    driveMinutes: driveMinutes,
    chargeMinutes: totalChargeMin,
    totalCostTl: totalCost,
    chargingStops: stops,
    availableRangeKm: availableRangeKm,
  );
}

String _stopName(_City origin, _City destination, double fraction) {
  if (fraction < 0.4) return '${origin.name} çıkışı yakını';
  if (fraction > 0.6) return '${destination.name} girişi yakını';
  return '${origin.name}–${destination.name} orta noktası';
}

// ---------------------------------------------------------------------------
// Ekran
// ---------------------------------------------------------------------------

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  _City _origin = _turkishCities[0]; // İstanbul
  _City _destination = _turkishCities[1]; // Ankara
  VehiclePreset _vehicle = VehiclePreset.presets.first;
  double _startSoc = 80;
  TripStrategy _strategy = TripStrategy.balanced;
  TripPlanResult? _result;
  bool _isCalculating = false;

  Future<void> _planTrip() async {
    if (_origin.name == _destination.name) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlangıç ve varış aynı olamaz.')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    // 400ms yapay gecikme — hesaplanıyor hissi verir
    await Future.delayed(const Duration(milliseconds: 400));

    final result = _calculateOffline(
      origin: _origin,
      destination: _destination,
      vehicle: _vehicle,
      startSoc: _startSoc,
      strategy: _strategy,
    );

    // Aynı zamanda Firestore'a kaydet girişimi (arka planda, sessizce)
    _trySaveToFirestore(result);

    setState(() {
      _result = result;
      _isCalculating = false;
    });
  }

  void _trySaveToFirestore(TripPlanResult result) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    ref.read(tripPlannerControllerProvider.notifier).saveCurrentTrip(
          result: result,
          origin: TripLocation(
              name: _origin.name, lat: _origin.lat, lng: _origin.lng),
          destination: TripLocation(
              name: _destination.name,
              lat: _destination.lat,
              lng: _destination.lng),
          vehicle: _vehicle,
          startSoc: _startSoc,
          strategy: _strategy,
          userId: user.uid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(userTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Güzergah Planlayıcı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Başlangıç şehri ──────────────────────────────────────────
            _CityDropdown(
              label: 'Başlangıç',
              icon: Icons.trip_origin,
              value: _origin,
              onChanged: (c) => setState(() => _origin = c),
            ),
            const SizedBox(height: 12),

            // ── Şehir swap butonu ─────────────────────────────────────────
            Center(
              child: IconButton(
                icon: const Icon(Icons.swap_vert, color: AppColors.primary),
                tooltip: 'Şehirleri Değiştir',
                onPressed: () => setState(() {
                  final tmp = _origin;
                  _origin = _destination;
                  _destination = tmp;
                }),
              ),
            ),

            // ── Varış şehri ───────────────────────────────────────────────
            _CityDropdown(
              label: 'Varış',
              icon: Icons.flag,
              value: _destination,
              onChanged: (c) => setState(() => _destination = c),
            ),
            const SizedBox(height: 16),

            // ── Mesafe önizleme ───────────────────────────────────────────
            if (_origin.name != _destination.name)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.cardBorder,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Tahmini mesafe: ~${(_haversineKm(_origin, _destination) * 1.15).toStringAsFixed(0)} km',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Araç modeli ───────────────────────────────────────────────
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

            // ── Batarya seviyesi ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Başlangıç Bataryası'),
                Text(
                  '%${_startSoc.toInt()}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _startSoc,
              min: 10,
              max: 100,
              divisions: 18,
              label: '%${_startSoc.toInt()}',
              onChanged: (v) => setState(() => _startSoc = v),
            ),
            const SizedBox(height: 8),

            // ── Strateji ──────────────────────────────────────────────────
            const Text(
              'Rota Stratejisi',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TripStrategy.values.map((s) {
                return ChoiceChip(
                  label: Text(_strategyLabel(s)),
                  selected: _strategy == s,
                  onSelected: (_) => setState(() => _strategy = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Rota Oluştur butonu ────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isCalculating ? null : _planTrip,
              icon: _isCalculating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.directions),
              label: Text(_isCalculating ? 'Hesaplanıyor...' : 'Rota Oluştur'),
            ),
            const SizedBox(height: 24),

            // ── Rota sonucu ───────────────────────────────────────────────
            if (_result != null)
              _PlanResultCard(
                result: _result!,
                origin: _origin,
                destination: _destination,
              ),
            const SizedBox(height: 24),

            // ── Geçmiş rotalar ────────────────────────────────────────────
            const Text(
              'Geçmiş Rotalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return const AppCard(
                    child: Text(
                      'Henüz kaydedilmiş rota yok.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return Column(
                  children: trips
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.route,
                                    color: Colors.black, size: 18),
                              ),
                              title: Text(
                                '${t.origin.name} → ${t.destination.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${t.distanceKm.toStringAsFixed(0)} km  •  '
                                '${t.totalMinutes} dk  •  '
                                '₺${t.totalCostTl.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const ShimmerCard(),
              error: (e, _) => Text('Hata: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  String _strategyLabel(TripStrategy s) => switch (s) {
        TripStrategy.fastest => '⚡ En Hızlı',
        TripStrategy.cheapest => '💰 En Ucuz',
        TripStrategy.balanced => '⚖️ Dengeli',
        TripStrategy.safest => '🛡️ En Güvenli',
      };
}

// ---------------------------------------------------------------------------
// Şehir dropdown bileşeni
// ---------------------------------------------------------------------------

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final _City value;
  final void Function(_City) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_City>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: _turkishCities
          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
          .toList(),
      onChanged: (c) {
        if (c != null) onChanged(c);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Rota sonuç kartı
// ---------------------------------------------------------------------------

class _PlanResultCard extends StatelessWidget {
  const _PlanResultCard({
    required this.result,
    required this.origin,
    required this.destination,
  });

  final TripPlanResult result;
  final _City origin;
  final _City destination;

  @override
  Widget build(BuildContext context) {
    final totalMin = result.driveMinutes + result.chargeMinutes;
    final totalHours = totalMin ~/ 60;
    final totalMins = totalMin % 60;

    return AppCard(
      gradient: AppColors.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${origin.name} → ${destination.name}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Özet istatistikler
          Row(
            children: [
              _Stat(
                icon: Icons.straighten,
                label: 'Mesafe',
                value: '${result.distanceKm.toStringAsFixed(0)} km',
              ),
              _Stat(
                icon: Icons.timer,
                label: 'Toplam Süre',
                value: totalHours > 0
                    ? '${totalHours}s ${totalMins}dk'
                    : '$totalMins dk',
              ),
              _Stat(
                icon: Icons.payments,
                label: 'Maliyet',
                value: result.totalCostTl > 0
                    ? '₺${result.totalCostTl.toStringAsFixed(0)}'
                    : 'Ücretsiz',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(
                icon: Icons.drive_eta,
                label: 'Sürüş',
                value: '${result.driveMinutes} dk',
              ),
              _Stat(
                icon: Icons.ev_station,
                label: 'Şarj Süresi',
                value: result.chargeMinutes > 0
                    ? '${result.chargeMinutes} dk'
                    : 'Yok',
              ),
              _Stat(
                icon: Icons.battery_charging_full,
                label: 'Mevcut Menzil',
                value: '${result.availableRangeKm.toStringAsFixed(0)} km',
              ),
            ],
          ),

          // Şarj durakları
          if (result.chargingStops.isNotEmpty) ...[
            const Divider(height: 24, color: AppColors.border),
            const Text(
              'Şarj Durakları',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...result.chargingStops.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.stationName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${s.chargeMinutes} dk şarj  •  ₺${s.costTl.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.ev_station,
                        color: AppColors.primary, size: 18),
                  ],
                ),
              );
            }),
          ] else ...[
            const Divider(height: 24, color: AppColors.border),
            const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tek şarj yeterli — durak gerekmez!',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon,
              size: 18,
              color: highlight ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 15 : 13,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
