// lib/core/config/providers/user_preferences_provider.dart

import '../../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../models/user_preferences.dart';
import '../services/user_preferences_service.dart';

/// 用户偏好服务提供者
final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserPreferencesService(prefs);
});

/// 用户偏好提供者（异步加载）
final userPreferencesAsyncProvider = FutureProvider<UserPreferences>((
  ref,
) async {
  final service = ref.watch(userPreferencesServiceProvider);
  return await service.loadPreferences();
});

/// 用户偏好状态管理器
class UserPreferencesNotifier
    extends StateNotifier<AsyncValue<UserPreferences>> {
  final UserPreferencesService _service;

  UserPreferencesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadPreferences();
  }

  /// 加载偏好设置
  Future<void> _loadPreferences() async {
    try {
      state = const AsyncValue.loading();
      final preferences = await _service.loadPreferences();
      state = AsyncValue.data(preferences);
      AppLogger.debug('UserPreferencesNotifier: 偏好设置加载成功');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('UserPreferencesNotifier: 偏好设置加载失败: $e');
    }
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    try {
      final updatedPrefs = await _service.setLanguage(language);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 语言设置为 $language');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置通知开关
  Future<void> setNotifications(bool enabled) async {
    try {
      final updatedPrefs = await _service.setNotifications(enabled);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 通知设置为 $enabled');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置震动反馈
  Future<void> setVibration(bool enabled) async {
    try {
      final updatedPrefs = await _service.setVibration(enabled);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 震动设置为 $enabled');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置声音反馈
  Future<void> setSound(bool enabled) async {
    try {
      final updatedPrefs = await _service.setSound(enabled);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 声音设置为 $enabled');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置缓存限制
  Future<void> setCacheLimit(int limitMB) async {
    try {
      final updatedPrefs = await _service.setCacheLimit(limitMB);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 缓存限制设置为 ${limitMB}MB');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置数据保护模式
  Future<void> setDataSaver(bool enabled) async {
    try {
      final updatedPrefs = await _service.setDataSaver(enabled);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 数据保护模式设置为 $enabled');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 标记为非首次启动
  Future<void> markNotFirstLaunch() async {
    try {
      final updatedPrefs = await _service.markNotFirstLaunch();
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 标记为非首次启动');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 标记为已同步
  Future<void> markSynced() async {
    try {
      final updatedPrefs = await _service.markSynced();
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 标记为已同步');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置自定义数据
  Future<void> setCustomData(String key, dynamic value) async {
    try {
      final updatedPrefs = await _service.setCustomData(key, value);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 设置自定义数据 $key');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 移除自定义数据
  Future<void> removeCustomData(String key) async {
    try {
      final updatedPrefs = await _service.removeCustomData(key);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 移除自定义数据 $key');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 批量更新偏好设置
  Future<void> updateMultiple(Map<String, dynamic> updates) async {
    try {
      final updatedPrefs = await _service.updateMultiplePreferences(updates);
      state = AsyncValue.data(updatedPrefs);
      AppLogger.debug('UserPreferencesNotifier: 批量更新${updates.length}个设置');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    try {
      final defaultPrefs = await _service.resetToDefault();
      state = AsyncValue.data(defaultPrefs);
      AppLogger.debug('UserPreferencesNotifier: 重置为默认偏好设置');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    await _loadPreferences();
  }

  /// 获取当前偏好设置（同步）
  UserPreferences? get currentPreferences {
    return state.whenOrNull(data: (prefs) => prefs);
  }
}

/// 用户偏好状态管理提供者
final userPreferencesNotifierProvider =
    StateNotifierProvider<UserPreferencesNotifier, AsyncValue<UserPreferences>>(
      (ref) {
        final service = ref.watch(userPreferencesServiceProvider);
        return UserPreferencesNotifier(service);
      },
    );

// ===== 派生状态提供者 =====

/// 当前语言提供者
final currentLanguageProvider = Provider<String>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => prefs.language,
    loading: () => 'zh-CN',
    error: (_, _) => 'zh-CN',
  );
});

/// 通知设置提供者
final notificationSettingsProvider = Provider<Map<String, bool>>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => {
      'notifications': prefs.enableNotifications,
      'vibration': prefs.enableVibration,
      'sound': prefs.enableSound,
    },
    loading: () => {'notifications': true, 'vibration': true, 'sound': true},
    error: (_, _) => {'notifications': true, 'vibration': true, 'sound': true},
  );
});

/// 性能设置提供者
final performanceSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => {
      'cacheLimit': prefs.cacheLimit,
      'dataSaver': prefs.enableDataSaver,
    },
    loading: () => {'cacheLimit': 100, 'dataSaver': false},
    error: (_, _) => {'cacheLimit': 100, 'dataSaver': false},
  );
});

/// 首次启动检查提供者
final isFirstLaunchProvider = Provider<bool>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => prefs.isFirstLaunch,
    loading: () => true,
    error: (_, _) => true,
  );
});

/// 需要同步检查提供者
final needsSyncProvider = Provider<bool>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => prefs.needsSync,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// 上次同步时间提供者
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final prefsAsync = ref.watch(userPreferencesNotifierProvider);
  return prefsAsync.when(
    data: (prefs) => prefs.lastSyncTime,
    loading: () => null,
    error: (_, _) => null,
  );
});

// ===== 个别设置提供者 =====

/// 通知开关提供者
final enableNotificationsProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['notifications'] ?? true;
});

/// 震动反馈提供者
final enableVibrationProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['vibration'] ?? true;
});

/// 声音反馈提供者
final enableSoundProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings['sound'] ?? true;
});

/// 缓存限制提供者
final cacheLimitProvider = Provider<int>((ref) {
  final settings = ref.watch(performanceSettingsProvider);
  return settings['cacheLimit'] ?? 100;
});

/// 数据保护模式提供者
final enableDataSaverProvider = Provider<bool>((ref) {
  final settings = ref.watch(performanceSettingsProvider);
  return settings['dataSaver'] ?? false;
});

// ===== 便利提供者 =====

/// 自定义数据提供者工厂
Provider<T?> customDataProvider<T>(String key) {
  return Provider<T?>((ref) {
    final prefsAsync = ref.watch(userPreferencesNotifierProvider);
    return prefsAsync.when(
      data: (prefs) => prefs.getCustomData<T>(key),
      loading: () => null,
      error: (_, _) => null,
    );
  });
}

/// 语言选项提供者
final languageOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'value': 'zh-CN', 'label': '简体中文'},
    {'value': 'zh-TW', 'label': '繁體中文'},
    {'value': 'en-US', 'label': 'English'},
    {'value': 'ja-JP', 'label': '日本語'},
  ];
});

/// 缓存限制选项提供者
final cacheLimitOptionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'value': 50, 'label': '50 MB'},
    {'value': 100, 'label': '100 MB'},
    {'value': 200, 'label': '200 MB'},
    {'value': 500, 'label': '500 MB'},
    {'value': 1000, 'label': '1 GB'},
  ];
});
