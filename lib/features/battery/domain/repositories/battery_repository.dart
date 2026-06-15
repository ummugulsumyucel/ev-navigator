import '../entities/battery_report_entity.dart';

abstract class BatteryRepository {
  Stream<List<BatteryReportEntity>> watchUserReports(String userId, {int limit = 90});

  Future<BatteryReportEntity?> getLatestReport(String userId);
}
