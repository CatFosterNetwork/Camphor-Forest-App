// lib/core/config/providers/app_config_provider.dart

import '../../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../models/app_config.dart';
import '../services/app_config_service.dart';

/// 应用配置服务提供者
final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppConfigService(prefs);
});

/// 应用配置提供者（异步加载）
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final service = ref.watch(appConfigServiceProvider);
  return await service.loadConfig();
});

/// 应用配置状态管理器
class AppConfigNotifier extends StateNotifier<AsyncValue<AppConfig>> {
  final AppConfigService _service;

  AppConfigNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      state = const AsyncValue.loading();
      final config = await _service.loadConfig();
      state = AsyncValue.data(config);
      AppLogger.debug('AppConfigNotifier: 配置加载成功');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('AppConfigNotifier: 配置加载失败: $e');
    }
  }

  /// 更新单个配置项
  Future<void> updateConfigItem(String key, bool value) async {
    try {
      final updatedConfig = await _service.updateConfigItem(key, value);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('AppConfigNotifier: 更新配置项 $key = $value');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('AppConfigNotifier: 更新配置项失败: $e');
    }
  }

  /// 批量更新配置项
  Future<void> updateMultipleItems(Map<String, bool> updates) async {
    try {
      final updatedConfig = await _service.updateMultipleItems(updates);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('AppConfigNotifier: 批量更新${updates.length}个配置项');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('AppConfigNotifier: 批量更新配置失败: $e');
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    try {
      final defaultConfig = await _service.resetToDefault();
      state = AsyncValue.data(defaultConfig);
      AppLogger.debug('AppConfigNotifier: 重置为默认配置');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('AppConfigNotifier: 重置配置失败: $e');
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadConfig();
  }

  /// 获取当前配置（同步）
  AppConfig? get currentConfig {
    return state.whenOrNull(data: (config) => config);
  }

  /// 检查是否有配置数据
  bool get hasData => state.hasValue;

  /// 检查是否正在加载
  bool get isLoading => state.isLoading;

  /// 检查是否有错误
  bool get hasError => state.hasError;
}

/// 应用配置状态管理提供者
final appConfigNotifierProvider =
    StateNotifierProvider<AppConfigNotifier, AsyncValue<AppConfig>>((ref) {
      final service = ref.watch(appConfigServiceProvider);
      return AppConfigNotifier(service);
    });

// ===== 派生状态提供者 =====

/// 首页显示配置提供者
final indexDisplayConfigProvider = Provider<Map<String, bool>>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.indexDisplaySettings,
    loading: () => {}, // 加载中返回空Map
    error: (_, _) => {}, // 错误时返回空Map
  );
});

/// 森林功能配置提供者
final forestFeatureConfigProvider = Provider<Map<String, bool>>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.forestFeatureSettings,
    loading: () => {}, // 加载中返回空Map
    error: (_, _) => {}, // 错误时返回空Map
  );
});

/// 自动同步设置提供者
final autoSyncConfigProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.autoSync,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// 自动续签服务设置提供者
final autoRenewalCheckInConfigProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.autoRenewalCheckInService,
    loading: () => false,
    error: (_, _) => false,
  );
});

// ===== 功能检查提供者 =====

/// 检查是否有任何森林功能启用
final hasAnyForestFeatureEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.hasAnyForestFeatureEnabled,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// 检查是否有任何首页功能启用
final hasAnyIndexFeatureEnabledProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(appConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.hasAnyIndexFeatureEnabled,
    loading: () => true, // 加载中默认显示
    error: (_, _) => true, // 错误时默认显示
  );
});

// ===== 便利提供者 =====

/// 特定首页功能启用状态提供者工厂
Provider<bool> indexFeatureEnabledProvider(String featureKey) {
  return Provider<bool>((ref) {
    final config = ref.watch(indexDisplayConfigProvider);
    return config[featureKey] ?? false;
  });
}

/// 特定森林功能启用状态提供者工厂
Provider<bool> forestFeatureEnabledProvider(String featureKey) {
  return Provider<bool>((ref) {
    final config = ref.watch(forestFeatureConfigProvider);
    return config[featureKey] ?? false;
  });
}

// ===== 预定义的功能提供者 =====

/// 常用的首页功能启用状态提供者
final showTodoProvider = indexFeatureEnabledProvider('index-showTodo');
final showExpenseProvider = indexFeatureEnabledProvider('index-showExpense');
final showClassroomProvider = indexFeatureEnabledProvider(
  'index-showClassroom',
);
final showExamsProvider = indexFeatureEnabledProvider('index-showExams');
final showGradesProvider = indexFeatureEnabledProvider('index-showGrades');
final showIndexServicesProvider = indexFeatureEnabledProvider(
  'index-showIndexServices',
);

/// 常用的森林功能启用状态提供者
final showSchoolNavigationProvider = forestFeatureEnabledProvider(
  'forest-showSchoolNavigation',
);
final showBBSProvider = forestFeatureEnabledProvider('forest-showBBS');
final showLifeServiceProvider = forestFeatureEnabledProvider(
  'forest-showLifeService',
);
final showFeedbackProvider = forestFeatureEnabledProvider(
  'forest-showFeedback',
);
final showLibraryProvider = forestFeatureEnabledProvider('forest-showLibrary');
final showFleaMarketProvider = forestFeatureEnabledProvider(
  'forest-showFleaMarket',
);
