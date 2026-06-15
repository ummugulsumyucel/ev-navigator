import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/cost_calculator.dart';
import '../providers/cost_providers.dart';

class CostCalculatorScreen extends ConsumerWidget {
  const CostCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(costInputProvider);
    final result = ref.watch(costResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maliyet Hesaplayıcı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elektrik Fiyatı: ₺${input.electricityPrice.toStringAsFixed(2)}/kWh',
                  ),
                  Slider(
                    value: input.electricityPrice,
                    min: 2,
                    max: 12,
                    divisions: 20,
                    label: '₺${input.electricityPrice.toStringAsFixed(2)}',
                    onChanged: ref
                        .read(costInputProvider.notifier)
                        .setElectricityPrice,
                  ),
                  const SizedBox(height: 8),
                  const Text('Şarj Tipi'),
                  SegmentedButton<ChargeType>(
                    segments: const [
                      ButtonSegment(value: ChargeType.ac, label: Text('AC')),
                      ButtonSegment(value: ChargeType.dc, label: Text('DC')),
                    ],
                    selected: {input.chargeType},
                    onSelectionChanged: (s) => ref
                        .read(costInputProvider.notifier)
                        .setChargeType(s.first),
                  ),
                  const SizedBox(height: 12),
                  Text('Aylık KM: ${input.monthlyKm.toStringAsFixed(0)}'),
                  Slider(
                    value: input.monthlyKm,
                    min: 500,
                    max: 5000,
                    divisions: 18,
                    label: input.monthlyKm.toStringAsFixed(0),
                    onChanged:
                        ref.read(costInputProvider.notifier).setMonthlyKm,
                  ),
                  Text(
                    'Tüketim: ${input.efficiency.toStringAsFixed(1)} kWh/100km',
                  ),
                  Slider(
                    value: input.efficiency,
                    min: 12,
                    max: 28,
                    divisions: 16,
                    label: input.efficiency.toStringAsFixed(1),
                    onChanged:
                        ref.read(costInputProvider.notifier).setEfficiency,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  label: 'EV Maliyeti',
                  value: '₺${result.evMonthlyCost.toStringAsFixed(0)}',
                  icon: Icons.electric_bolt,
                  subtitle: 'Aylık',
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Benzin',
                  value: '₺${result.petrolMonthlyCost.toStringAsFixed(0)}',
                  icon: Icons.local_gas_station,
                  subtitle: 'Aylık',
                ),
                StatCard(
                  label: 'Dizel',
                  value: '₺${result.dieselMonthlyCost.toStringAsFixed(0)}',
                  icon: Icons.local_gas_station,
                  subtitle: 'Aylık',
                ),
                StatCard(
                  label: 'Aylık Tasarruf',
                  value: '₺${result.monthlySavings.toStringAsFixed(0)}',
                  icon: Icons.savings,
                  subtitle: 'EV vs benzin',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yıllık Tasarruf',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${result.yearlySavings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EV: ₺${result.evCostPerKm.toStringAsFixed(2)}/km • '
                    'Benzin: ₺${result.petrolCostPerKm.toStringAsFixed(2)}/km',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [
                          result.evMonthlyCost,
                          result.petrolMonthlyCost,
                          result.dieselMonthlyCost,
                        ].reduce((a, b) => a > b ? a : b) *
                        1.2,
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
                          getTitlesWidget: (v, _) {
                            const labels = ['EV', 'Benzin', 'Dizel'];
                            final i = v.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              labels[i],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) => Text(
                            '₺${v.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: result.evMonthlyCost,
                            color: AppColors.primary,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: result.petrolMonthlyCost,
                            color: AppColors.warning,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: result.dieselMonthlyCost,
                            color: AppColors.textMuted,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
