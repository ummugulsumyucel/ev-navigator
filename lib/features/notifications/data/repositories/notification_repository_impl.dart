import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  static const _collection = 'notifications';

  @override
  Stream<List<AppNotificationEntity>> watchUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map(NotificationModel.fromFirestore)
          .map((m) => m.toEntity())
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'read': true,
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
