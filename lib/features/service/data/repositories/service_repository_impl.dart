import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ServiceEntity>> watchServices() {
    return _firestore.collection('services').snapshots().map((s) {
      return s.docs
          .map(ServiceModel.fromFirestore)
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
    });
  }

  @override
  Future<void> createAppointment({
    required String userId,
    required String serviceId,
    required String serviceName,
    required String serviceType,
    required DateTime date,
  }) async {
    await _firestore.collection('appointments').add({
      'userId': userId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceType': serviceType,
      'date': Timestamp.fromDate(date),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AppointmentEntity>> watchUserAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((doc) {
        final data = doc.data();
        return AppointmentEntity(
          id: doc.id,
          userId: data['userId'] as String,
          serviceId: data['serviceId'] as String? ?? '',
          serviceName: data['serviceName'] as String? ?? '',
          serviceType: data['serviceType'] as String? ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] as String? ?? 'pending',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }
}
