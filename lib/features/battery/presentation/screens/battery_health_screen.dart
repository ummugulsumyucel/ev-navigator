import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../domain/entities/battery_report_entity.dart';
import '../providers/battery_providers.dart';

class BatteryHealthScreen extends ConsumerWidget {
  const BatteryHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(batteryReportsProvider);
    final chartData = ref.watch(batteryChartDataProvider);
    final period = ref.watch(batteryChartPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batarya Sağlığı')),
      body: reportsAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Batarya verisi yok. Firebase battery_reports koleksiyonuna veri ekleyin.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final latest = reports.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'SOH',
                      value: '%${latest.soh.toStringAsFixed(1)}',
                      icon: Icons.favorite,
                      subtitle: 'Batarya sağlığı',
                      color: latest.soh >= 90
                          ? AppColors.primary
                          : latest.soh >= 80
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                    StatCard(
                      label: 'SOC',
                      value: '%${latest.soc.toStringAsFixed(0)}',
                      icon: Icons.battery_5_bar,
                      subtitle: 'Anlık şarj',
                    ),
                    StatCard(
                      label: 'Döngü',
                      value: '${latest.chargeCycles}',
                      icon: Icons.loop,
                      subtitle: 'Şarj döngüsü',
                    ),
                    StatCard(
                      label: 'Sıcaklık',
                      value: '${latest.temperatureC.toStringAsFixed(1)}°C',
                      icon: Icons.thermostat,
                      subtitle: 'Batarya sıcaklığı',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Gerçek Menzil',
                        value: '${latest.realRangeKm.toStringAsFixed(0)} km',
                        icon: Icons.route,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Ort. Tüketim',
                        value:
                            '${latest.efficiencyKwhPer100km.toStringAsFixed(1)} kWh',
                        icon: Icons.speed,
                        subtitle: '/100 km',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SOH Trendi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SegmentedButton<BatteryChartPeriod>(
                      segments: const [
                        ButtonSegment(
                          value: BatteryChartPeriod.daily,
                          label: Text('Günlük'),
                        ),
                        ButtonSegment(
                          value: BatteryChartPeriod.weekly,
                          label: Text('Haftalık'),
                        ),
                        ButtonSegment(
                          value: BatteryChartPeriod.monthly,
                          label: Text('Aylık'),
                        ),
                      ],
                      selected: {period},
                      onSelectionChanged: (s) {
                        ref.read(batteryChartPeriodProvider.notifier).state =
                            s.first;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: SizedBox(
                    height: 220,
                    child: chartData.length < 2
                        ? const Center(
                            child: Text('Grafik için daha fazla veri gerekli'))
                        : _SohChart(reports: chartData),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: SizedBox(
                    height: 220,
                    child: chartData.length < 2
                        ? const Center(
                            child: Text('Grafik için daha fazla veri gerekli'))
                        : _EfficiencyChart(reports: chartData),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SohChart extends StatelessWidget {
  const _SohChart({required this.reports});
  final List<BatteryReportEntity> reports;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= reports.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${reports[i].recordedAt.day}/${reports[i].recordedAt.month}',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: reports
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.soh))
                .toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _EfficiencyChart extends StatelessWidget {
  const _EfficiencyChart({required this.reports});
  final List<BatteryReportEntity> reports;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= reports.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${reports[i].recordedAt.day}/${reports[i].recordedAt.month}',
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        barGroups: reports.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.efficiencyKwhPer100km,
                color: AppColors.secondary,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
