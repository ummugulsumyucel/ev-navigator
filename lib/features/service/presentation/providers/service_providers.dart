import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.watch(firestoreProvider));
});

final servicesStreamProvider = StreamProvider<List<ServiceEntity>>((ref) {
  return ref.watch(serviceRepositoryProvider).watchServices();
});

final userAppointmentsProvider =
    StreamProvider<List<AppointmentEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(serviceRepositoryProvider).watchUserAppointments(user.uid);
});

final serviceSearchProvider = StateProvider<String>((ref) => '');

final filteredServicesProvider = Provider<AsyncValue<List<ServiceEntity>>>((ref) {
  final servicesAsync = ref.watch(servicesStreamProvider);
  final query = ref.watch(serviceSearchProvider).toLowerCase();

  return servicesAsync.whenData((services) {
    if (query.isEmpty) return services;
    return services
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.brand.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query))
        .toList();
  });
});
