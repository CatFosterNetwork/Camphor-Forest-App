// lib/core/config/providers/new_core_providers.dart
// 新的配置系统的核心Riverpod提供者

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 导入统一配置服务provider
import 'unified_config_service_provider.dart';

// 导入所有配置提供者
export 'app_config_provider.dart';
export 'theme_config_provider.dart' hide effectiveDarkModeProvider;
export 'user_preferences_provider.dart';
export 'unified_config_service_provider.dart' hide unifiedConfigServiceProvider;

// ===== 新配置系统的主要提供者 =====

/// 新配置系统已完全启用
/// 不再需要逐步迁移标志
final newConfigSystemEnabledProvider = Provider<bool>((ref) => true);

/// 配置系统初始化检查提供者
final configSystemInitializedProvider = Provider<bool>((ref) {
  final configState = ref.watch(configInitializationProvider);
  return configState.when(
    data: (result) => result.success,
    loading: () => false,
    error: (_, _) => false,
  );
});

// ===== 迁移完成，兼容性提供者已移除 =====

// ===== 功能开关提供者（替换旧的ForestFeaturesProvider） =====

/// 森林功能启用状态提供者（新配置系统）
final newForestFeaturesConfigProvider = Provider<Map<String, bool>>((ref) {
  final appConfig = ref.watch(quickAppConfigProvider);
  return appConfig?.forestFeatureSettings ?? {};
});

/// 森林功能是否显示提供者
final newShouldShowForestFeaturesProvider = Provider<bool>((ref) {
  final appConfig = ref.watch(quickAppConfigProvider);
  return appConfig?.hasAnyForestFeatureEnabled ?? false;
});

// ===== 快速访问特定功能的提供者 =====

/// 特定森林功能启用状态提供者工厂（兼容旧API）
Provider<bool> newForestFeatureEnabledProvider(String featureAbbr) {
  return Provider<bool>((ref) {
    final config = ref.watch(newForestFeaturesConfigProvider);
    final key = 'forest-show$featureAbbr';
    return config[key] ?? false;
  });
}

/// 首页功能启用状态提供者工厂
Provider<bool> newIndexFeatureEnabledProvider(String featureKey) {
  return Provider<bool>((ref) {
    final appConfig = ref.watch(quickAppConfigProvider);
    final indexSettings = appConfig?.indexDisplaySettings ?? {};
    return indexSettings[featureKey] ?? false;
  });
}

// ===== 预定义的兼容性提供者 =====

/// 兼容旧的森林功能提供者
final newShowSchoolNavigationProvider = newForestFeatureEnabledProvider(
  'SchoolNavigation',
);
final newShowBBSProvider = newForestFeatureEnabledProvider('BBS');
final newShowLifeServiceProvider = newForestFeatureEnabledProvider(
  'LifeService',
);
final newShowFeedbackProvider = newForestFeatureEnabledProvider('Feedback');
final newShowLibraryProvider = newForestFeatureEnabledProvider('Library');

// ===== 迁移后的新配置系统监控和调试 =====

/// 配置加载性能监控提供者
final configLoadingPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  // 计算配置加载性能指标
  final startTime = DateTime.now();

  // 检查配置健康状态
  final healthStatus = await ref.read(configHealthProvider.future);
  final isLoaded = healthStatus['status'] == 'healthy';

  final endTime = DateTime.now();
  final loadingTime = endTime.difference(startTime).inMilliseconds;

  return {
    'loadingTime': loadingTime,
    'configsLoaded': isLoaded ? 3 : 0, // 三个配置系统
    'systemHealth': healthStatus,
    'allConfigsLoaded': isLoaded,
    'performanceGrade': isLoaded ? 'A' : 'C',
  };
});

// ===== 清理完成的迁移标记 =====

/// 配置迁移已完成
/// 所有功能已迁移到新的配置系统：AppConfig, ThemeConfig, UserPreferences

// ===== 调试和开发辅助提供者 =====

/// 配置对比提供者（验证配置系统状态）
final configComparisonProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  try {
    final health = await ref.read(configHealthProvider.future);
    final configState = ref.read(configInitializationProvider);

    return configState.when(
      data: (result) => {
        'comparison': 'completed',
        'systemStatus': {
          'unified': true,
          'appConfig': result.appConfig != null,
          'themeConfig': result.themeConfig != null,
          'userPrefs': result.userPreferences != null,
        },
        'health': health,
        'migrationStatus': 'completed',
        'configSource': result.success ? 'unified_service' : 'fallback',
      },
      loading: () => {
        'comparison': 'loading',
        'systemStatus': {'loading': true},
      },
      error: (error, _) => {'comparison': 'error', 'error': error.toString()},
    );
  } catch (e) {
    return {'error': e.toString()};
  }
});

/// 配置系统日志提供者
final configSystemLogProvider = Provider<List<String>>((ref) {
  final configState = ref.watch(configInitializationProvider);
  final health = ref.watch(configHealthProvider);

  final logs = <String>[
    'Unified Configuration System v2.0',
    'Architecture: AppConfig + ThemeConfig + UserPreferences',
    'Provider: UnifiedConfigService',
    'Status: ${configState.when(data: (result) => result.success ? 'Active' : 'Failed', loading: () => 'Initializing', error: (_, _) => 'Error')}',
  ];

  health.whenData((healthData) {
    if (healthData['status'] == 'healthy') {
      logs.add('Health: All systems operational');
    } else {
      logs.add('Health: ${healthData['status'] ?? 'Unknown'}');
    }
  });

  return logs;
});
