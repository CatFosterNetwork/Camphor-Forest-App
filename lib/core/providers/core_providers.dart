// lib/core/providers/core_providers.dart

import 'package:camphor_forest/core/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../network/http_client.dart';
import '../services/api_service.dart';
import '../services/custom_theme_service.dart';
import '../services/image_upload_service.dart';
import '../config/services/unified_config_service.dart';

/// 1. Dio 实例
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: ApiConstants.defaultHeaders,
      responseType: ResponseType.json,
    ),
  );
});

/// 2. IHttpClient 抽象 + 实现
final httpClientProvider = Provider<HttpClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return HttpClient(secureStorage: storage);
});

/// 3. Secure Storage
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

/// 4. ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    ref.watch(httpClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(
    '请在 main.dart 中通过 overrides 注入 SharedPreferences',
  ),
);

/// 5. 自定义主题服务
final customThemeServiceProvider = Provider<CustomThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomThemeService(prefs);
});

/// 6. ImageUploadService
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ImageUploadService(api);
});

/// 7. UserService
/// 配置服务的 Provider 定义在 unified_config_service_provider.dart
final userServiceProvider = FutureProvider<UserService>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final api = ref.watch(apiServiceProvider);
  // 通过工厂方法创建配置服务，避免 Provider 循环依赖
  final configService = await UnifiedConfigService.create(
    ref.watch(sharedPreferencesProvider),
    ref.watch(customThemeServiceProvider),
    api,
  );
  return UserService(storage, configService, api);
});
