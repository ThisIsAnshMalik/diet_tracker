import 'package:diet_tracker/config/api_config.dart';
import 'package:dio/dio.dart';

Dio createUsdaDio() {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.usdaBaseUrl,
      connectTimeout: ApiConfig.searchConnectTimeout,
      receiveTimeout: ApiConfig.searchReceiveTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );
}

Dio createOpenFoodFactsDio() {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.openFoodFactsBaseUrl,
      connectTimeout: ApiConfig.searchConnectTimeout,
      receiveTimeout: ApiConfig.searchReceiveTimeout,
      headers: {
        'User-Agent': ApiConfig.openFoodFactsUserAgent,
        'Accept': 'application/json',
      },
    ),
  );
}