import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<AppNotificationEntity>> watchUserNotifications(String userId);

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead(String userId);

  Future<int> getUnreadCount(String userId);
}
