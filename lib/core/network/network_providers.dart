import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final directionsApiProvider = Provider<DirectionsApiClient>((ref) {
  return DirectionsApiClient(ref.watch(dioClientProvider).dio);
});
