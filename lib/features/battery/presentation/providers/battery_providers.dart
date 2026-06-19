import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/battery_repository_impl.dart';
import '../../domain/entities/battery_report_entity.dart';
import '../../domain/repositories/battery_repository.dart';

final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  return BatteryRepositoryImpl(ref.watch(firestoreProvider));
});

final batteryReportsProvider = StreamProvider<List<BatteryReportEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(batteryRepositoryProvider)
      .watchUserReports(user.uid)
      .map((reports) => reports.isEmpty ? _mockBatteryReports : reports);
});

final batteryChartPeriodProvider =
    StateProvider<BatteryChartPeriod>((ref) => BatteryChartPeriod.weekly);

final batteryChartDataProvider = Provider<List<BatteryReportEntity>>((ref) {
  final reports = ref.watch(batteryReportsProvider).valueOrNull ?? [];
  final period = ref.watch(batteryChartPeriodProvider);
  final now = DateTime.now();

  final cutoff = switch (period) {
    BatteryChartPeriod.daily => now.subtract(const Duration(days: 7)),
    BatteryChartPeriod.weekly => now.subtract(const Duration(days: 30)),
    BatteryChartPeriod.monthly => now.subtract(const Duration(days: 365)),
  };

  return reports.where((r) => r.recordedAt.isAfter(cutoff)).toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
});

// ---------------------------------------------------------------------------
// Statik demo veriler — Firestore boşken gösterilir
// ---------------------------------------------------------------------------
final _now = DateTime.now();

final List<BatteryReportEntity> _mockBatteryReports = [
  // En güncel kayıt (bugün)
  BatteryReportEntity(
    id: 'mock_b1',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 93.2,
    soc: 78.0,
    temperatureC: 24.5,
    chargeCycles: 187,
    realRangeKm: 412.0,
    efficiencyKwhPer100km: 17.1,
    recordedAt: _now,
  ),
  BatteryReportEntity(
    id: 'mock_b2',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 93.5,
    soc: 85.0,
    temperatureC: 23.0,
    chargeCycles: 185,
    realRangeKm: 416.0,
    efficiencyKwhPer100km: 16.9,
    recordedAt: _now.subtract(const Duration(days: 3)),
  ),
  BatteryReportEntity(
    id: 'mock_b3',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 93.8,
    soc: 62.0,
    temperatureC: 21.0,
    chargeCycles: 183,
    realRangeKm: 418.0,
    efficiencyKwhPer100km: 16.8,
    recordedAt: _now.subtract(const Duration(days: 7)),
  ),
  BatteryReportEntity(
    id: 'mock_b4',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 94.1,
    soc: 90.0,
    temperatureC: 19.5,
    chargeCycles: 180,
    realRangeKm: 421.0,
    efficiencyKwhPer100km: 16.6,
    recordedAt: _now.subtract(const Duration(days: 14)),
  ),
  BatteryReportEntity(
    id: 'mock_b5',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 94.5,
    soc: 55.0,
    temperatureC: 18.0,
    chargeCycles: 176,
    realRangeKm: 425.0,
    efficiencyKwhPer100km: 16.4,
    recordedAt: _now.subtract(const Duration(days: 21)),
  ),
  BatteryReportEntity(
    id: 'mock_b6',
    userId: 'demo',
    vehicleId: 'demo_vehicle',
    soh: 95.0,
    soc: 80.0,
    temperatureC: 22.0,
    chargeCycles: 170,
    realRangeKm: 430.0,
    efficiencyKwhPer100km: 16.2,
    recordedAt: _now.subtract(const Duration(days: 30)),
  ),
];
