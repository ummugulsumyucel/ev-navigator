enum NotificationType {
  stationOutage,
  chargeComplete,
  newComment,
  newFollower,
  news,
  appointment,
  unknown,
}

class AppNotificationEntity {
  const AppNotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  AppNotificationEntity copyWith({bool? read}) => AppNotificationEntity(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
        data: data,
      );
}
