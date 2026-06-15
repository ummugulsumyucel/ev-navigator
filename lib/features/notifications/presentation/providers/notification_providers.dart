import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(firestoreProvider));
});

final userNotificationsProvider =
    StreamProvider<List<AppNotificationEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications(user.uid);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final notifications = ref.watch(userNotificationsProvider).valueOrNull ?? [];
  return Stream.value(notifications.where((n) => !n.read).length);
});
