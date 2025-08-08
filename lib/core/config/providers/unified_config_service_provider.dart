// lib/core/config/providers/unified_config_service_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/unified_config_service.dart';
import '../../providers/core_providers.dart';
import '../models/app_config.dart';
import '../models/theme_config.dart';
import '../models/user_preferences.dart';

// 导出配置结果类型
export '../services/unified_config_service.dart' show ConfigResult, AllConfigs;

/// 统一配置服务Provider
final unifiedConfigServiceProvider = FutureProvider<UnifiedConfigService>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final customThemeService = ref.watch(customThemeServiceProvider);
  
  return await UnifiedConfigService.create(prefs, customThemeService);
});

/// 配置初始化状态Provider
final configInitializationProvider = StateNotifierProvider<ConfigInitNotifier, AsyncValue<ConfigResult>>((ref) {
  return ConfigInitNotifier(ref);
});

/// 配置初始化状态管理器
class ConfigInitNotifier extends StateNotifier<AsyncValue<ConfigResult>> {
  final Ref _ref;
  UnifiedConfigService? _service;

  ConfigInitNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  /// 初始化配置
  Future<void> _initialize() async {
    try {
      final service = await _ref.read(unifiedConfigServiceProvider.future);
      _service = service;
      
      final result = await service.initialize();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 从API数据更新配置
  Future<void> updateFromApiData(Map<String, dynamic> apiData) async {
    if (_service == null) return;
    
    try {
      state = const AsyncValue.loading();
      final result = await _service!.initialize(apiData: apiData);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重置配置
  Future<void> resetConfigs() async {
    if (_service == null) return;
    
    try {
      state = const AsyncValue.loading();
      final result = await _service!.resetAllConfigs();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 同步到服务器
  Future<bool> syncToServer() async {
    if (_service == null) return false;
    return await _service!.syncToServer();
  }

  /// 从服务器同步
  Future<void> syncFromServer() async {
    if (_service == null) return;
    
    try {
      state = const AsyncValue.loading();
      final result = await _service!.syncFromServer();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 快速访问应用配置Provider
final quickAppConfigProvider = Provider<AppConfig?>((ref) {
  final configState = ref.watch(configInitializationProvider);
  return configState.whenOrNull(data: (result) => result.appConfig);
});

/// 快速访问主题配置Provider  
final quickThemeConfigProvider = Provider<ThemeConfig?>((ref) {
  final configState = ref.watch(configInitializationProvider);
  return configState.whenOrNull(data: (result) => result.themeConfig);
});

/// 快速访问用户偏好Provider
final quickUserPreferencesProvider = Provider<UserPreferences?>((ref) {
  final configState = ref.watch(configInitializationProvider);
  return configState.whenOrNull(data: (result) => result.userPreferences);
});

/// 配置系统健康状态Provider
final configHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = await ref.watch(unifiedConfigServiceProvider.future);
  return await service.getHealthStatus();
});

/// 配置同步状态Provider
final configSyncStatusProvider = StateNotifierProvider<ConfigSyncNotifier, AsyncValue<String>>((ref) {
  return ConfigSyncNotifier(ref);
});

/// 配置同步状态管理器
class ConfigSyncNotifier extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;

  ConfigSyncNotifier(this._ref) : super(const AsyncValue.data('idle'));

  /// 执行同步到服务器
  Future<void> syncToServer() async {
    try {
      state = const AsyncValue.loading();
      final service = await _ref.read(unifiedConfigServiceProvider.future);
      final success = await service.syncToServer();
      
      if (success) {
        state = const AsyncValue.data('sync_success');
      } else {
        state = const AsyncValue.data('sync_failed');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 执行从服务器同步
  Future<void> syncFromServer() async {
    try {
      state = const AsyncValue.loading();
      final service = await _ref.read(unifiedConfigServiceProvider.future);
      final result = await service.syncFromServer();
      
      if (result.success) {
        // 触发配置重新初始化
        _ref.read(configInitializationProvider.notifier).updateFromApiData({});
        state = const AsyncValue.data('download_success');
      } else {
        state = const AsyncValue.data('download_failed');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重置状态
  void resetStatus() {
    state = const AsyncValue.data('idle');
  }
}

/// 有效深色模式Provider (兼容旧系统)
final effectiveDarkModeProvider = Provider<bool>((ref) {
  final themeConfig = ref.watch(quickThemeConfigProvider);
  return themeConfig?.getEffectiveDarkMode() ?? false;
});

/// 当前主题Provider (兼容旧系统)  
final currentSelectedThemeProvider = Provider<dynamic>((ref) {
  final themeConfig = ref.watch(quickThemeConfigProvider);
  return themeConfig?.selectedTheme;
});