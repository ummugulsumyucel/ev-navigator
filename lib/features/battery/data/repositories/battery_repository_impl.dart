import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/battery_report_entity.dart';
import '../../domain/repositories/battery_repository.dart';
import '../models/battery_report_model.dart';

class BatteryRepositoryImpl implements BatteryRepository {
  BatteryRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  static const _collection = 'battery_reports';

  @override
  Stream<List<BatteryReportEntity>> watchUserReports(
    String userId, {
    int limit = 90,
  }) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map(BatteryReportModel.fromFirestore)
          .map((m) => m.toEntity())
          .toList();
      list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return list;
    });
  }

  @override
  Future<BatteryReportEntity?> getLatestReport(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(10)
        .get();
    if (snap.docs.isEmpty) return null;
    final list = snap.docs
        .map(BatteryReportModel.fromFirestore)
        .map((m) => m.toEntity())
        .toList();
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list.first;
  }
}
