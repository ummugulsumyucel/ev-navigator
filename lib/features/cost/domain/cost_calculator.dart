enum ChargeType { ac, dc }

class CostCalculationResult {
  const CostCalculationResult({
    required this.evMonthlyCost,
    required this.petrolMonthlyCost,
    required this.dieselMonthlyCost,
    required this.monthlySavings,
    required this.yearlySavings,
    required this.evCostPerKm,
    required this.petrolCostPerKm,
    required this.dieselCostPerKm,
  });

  final double evMonthlyCost;
  final double petrolMonthlyCost;
  final double dieselMonthlyCost;
  final double monthlySavings;
  final double yearlySavings;
  final double evCostPerKm;
  final double petrolCostPerKm;
  final double dieselCostPerKm;
}

class CostCalculator {
  static const petrolPricePerLiter = 42.0;
  static const dieselPricePerLiter = 44.0;
  static const petrolConsumptionPer100km = 7.5;
  static const dieselConsumptionPer100km = 6.0;
  static const defaultEfficiencyKwhPer100km = 18.0;

  static CostCalculationResult calculate({
    required double electricityPricePerKwh,
    required ChargeType chargeType,
    required double monthlyKm,
    double efficiencyKwhPer100km = defaultEfficiencyKwhPer100km,
  }) {
    final acDcMultiplier = chargeType == ChargeType.dc ? 1.15 : 1.0;
    final evCostPerKm =
        (efficiencyKwhPer100km / 100) * electricityPricePerKwh * acDcMultiplier;
    const petrolCostPerKm =
        (petrolConsumptionPer100km / 100) * petrolPricePerLiter;
    const dieselCostPerKm =
        (dieselConsumptionPer100km / 100) * dieselPricePerLiter;

    final evMonthly = evCostPerKm * monthlyKm;
    final petrolMonthly = petrolCostPerKm * monthlyKm;
    final dieselMonthly = dieselCostPerKm * monthlyKm;
    final savings = petrolMonthly - evMonthly;

    return CostCalculationResult(
      evMonthlyCost: evMonthly,
      petrolMonthlyCost: petrolMonthly,
      dieselMonthlyCost: dieselMonthly,
      monthlySavings: savings,
      yearlySavings: savings * 12,
      evCostPerKm: evCostPerKm,
      petrolCostPerKm: petrolCostPerKm,
      dieselCostPerKm: dieselCostPerKm,
    );
  }
}
