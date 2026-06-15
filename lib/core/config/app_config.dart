/// Uygulama sabitleri ve API anahtarları.
class AppConfig {
  AppConfig._();

  static const String appName = 'EV Navigator';
  static const String appVersion = '1.0.0';

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyC7Mstk9XPuOGjDSUHbH77FdELPBJEEhxo',
  );

  static const String googleDirectionsApiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: '',
  );

  static const int paginationLimit = 20;
  static const int cacheTtlMinutes = 5;
  static const double defaultVehicleEfficiency = 18.0;
  static const double defaultBatteryKwh = 75.0;
  static const double defaultWltpRangeKm = 450.0;

  static bool get hasMapsKey => googleMapsApiKey.isNotEmpty;
}
