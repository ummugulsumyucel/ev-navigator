import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class DioClient {
  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final message = _mapError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error:
                  ApiException(message, statusCode: error.response?.statusCode),
            ),
          );
        },
      ),
    );
  }

  late final Dio _dio;
  Dio get dio => _dio;

  String _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Bağlantı zaman aşımına uğradı.';
      case DioExceptionType.connectionError:
        return 'İnternet bağlantısı yok.';
      default:
        return error.response?.data?['error_message'] as String? ??
            'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}

/// Google Directions API istemcisi
class DirectionsApiClient {
  DirectionsApiClient(this._dio);

  final Dio _dio;
  static const _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) async {
    const key = AppConfig.googleDirectionsApiKey;
    if (key.isEmpty) {
      throw const ApiException(
        'Google Directions API anahtarı yapılandırılmamış.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      _baseUrl,
      queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': mode,
        'key': key,
        'language': 'tr',
      },
    );

    if (response.data?['status'] != 'OK') {
      throw ApiException(
        response.data?['error_message'] as String? ?? 'Rota bulunamadı.',
      );
    }

    return response.data!;
  }
}
