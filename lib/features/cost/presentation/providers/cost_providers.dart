import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/cost_calculator.dart';

class CostInputState {
  const CostInputState({
    this.electricityPrice = 4.5,
    this.chargeType = ChargeType.ac,
    this.monthlyKm = 1500,
    this.efficiency = CostCalculator.defaultEfficiencyKwhPer100km,
  });

  final double electricityPrice;
  final ChargeType chargeType;
  final double monthlyKm;
  final double efficiency;

  CostInputState copyWith({
    double? electricityPrice,
    ChargeType? chargeType,
    double? monthlyKm,
    double? efficiency,
  }) {
    return CostInputState(
      electricityPrice: electricityPrice ?? this.electricityPrice,
      chargeType: chargeType ?? this.chargeType,
      monthlyKm: monthlyKm ?? this.monthlyKm,
      efficiency: efficiency ?? this.efficiency,
    );
  }
}

class CostInputNotifier extends StateNotifier<CostInputState> {
  CostInputNotifier() : super(const CostInputState());

  void setElectricityPrice(double v) =>
      state = state.copyWith(electricityPrice: v);
  void setChargeType(ChargeType v) => state = state.copyWith(chargeType: v);
  void setMonthlyKm(double v) => state = state.copyWith(monthlyKm: v);
  void setEfficiency(double v) => state = state.copyWith(efficiency: v);
}

final costInputProvider =
    StateNotifierProvider<CostInputNotifier, CostInputState>((ref) {
  return CostInputNotifier();
});

final costResultProvider = Provider<CostCalculationResult>((ref) {
  final input = ref.watch(costInputProvider);
  return CostCalculator.calculate(
    electricityPricePerKwh: input.electricityPrice,
    chargeType: input.chargeType,
    monthlyKm: input.monthlyKm,
    efficiencyKwhPer100km: input.efficiency,
  );
});
