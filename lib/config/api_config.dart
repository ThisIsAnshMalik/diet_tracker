/// API configuration. Pass USDA key at build time:
/// `flutter run --dart-define=USDA_API_KEY=your_key`
abstract final class ApiConfig {
  static const usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org';

  /// Build-time USDA FoodData Central key (not for production secret storage).
  static const usdaApiKey = String.fromEnvironment('USDA_API_KEY');

  static const openFoodFactsUserAgent =
      'DietTracker/1.0.0 (Flutter; diet-tracker-app)';

  static const searchConnectTimeout = Duration(seconds: 15);
  static const searchReceiveTimeout = Duration(seconds: 20);

  static const cacheMaxAge = Duration(days: 7);
  static const usdaPageSize = 25;
  static const offPageSize = 20;

  static bool get hasUsdaKey => usdaApiKey.isNotEmpty;
}
