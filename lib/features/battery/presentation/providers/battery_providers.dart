import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/battery_repository_impl.dart';
import '../../domain/entities/battery_report_entity.dart';
import '../../domain/repositories/battery_repository.dart';

final batteryRepositoryProvider = Provider<BatteryRepository>((ref) {
  return BatteryRepositoryImpl(ref.watch(firestoreProvider));
});

final batteryReportsProvider =
    StreamProvider<List<BatteryReportEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(batteryRepositoryProvider).watchUserReports(user.uid);
});

final batteryChartPeriodProvider =
    StateProvider<BatteryChartPeriod>((ref) => BatteryChartPeriod.weekly);

final batteryChartDataProvider =
    Provider<List<BatteryReportEntity>>((ref) {
  final reports = ref.watch(batteryReportsProvider).valueOrNull ?? [];
  final period = ref.watch(batteryChartPeriodProvider);
  final now = DateTime.now();

  final cutoff = switch (period) {
    BatteryChartPeriod.daily => now.subtract(const Duration(days: 7)),
    BatteryChartPeriod.weekly => now.subtract(const Duration(days: 30)),
    BatteryChartPeriod.monthly => now.subtract(const Duration(days: 365)),
  };

  return reports
      .where((r) => r.recordedAt.isAfter(cutoff))
      .toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
});
