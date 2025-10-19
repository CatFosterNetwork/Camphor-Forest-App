// lib/core/config/services/user_preferences_service.dart

import 'dart:convert';

import '../../../core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';

/// 用户偏好服务
/// 负责用户偏好配置的加载、保存和管理
class UserPreferencesService {
  static const String _configKey = 'user_preferences';

  final SharedPreferences _prefs;

  UserPreferencesService(this._prefs);

  /// 加载用户偏好
  Future<UserPreferences> loadPreferences() async {
    try {
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        final config = UserPreferences.fromJson(jsonDecode(configJson));
        AppLogger.debug('UserPreferencesService: 成功加载用户偏好');
        return config;
      }

      AppLogger.debug('UserPreferencesService: 使用默认用户偏好');
      return UserPreferences.defaultConfig;
    } catch (e) {
      AppLogger.debug('UserPreferencesService: 加载用户偏好失败，使用默认配置: $e');
      return UserPreferences.defaultConfig;
    }
  }

  /// 保存用户偏好
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final configJson = jsonEncode(preferences.toJson());
      await _prefs.setString(_configKey, configJson);
      AppLogger.debug('UserPreferencesService: 用户偏好已保存');
    } catch (e) {
      AppLogger.debug('UserPreferencesService: 保存用户偏好失败: $e');
      throw Exception('保存用户偏好失败: $e');
    }
  }

  /// 设置语言
  Future<UserPreferences> setLanguage(String language) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(language: language);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置语言为 $language');
    return updatedPrefs;
  }

  /// 设置通知开关
  Future<UserPreferences> setNotifications(bool enabled) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableNotifications: enabled);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置通知为 $enabled');
    return updatedPrefs;
  }

  /// 设置震动反馈
  Future<UserPreferences> setVibration(bool enabled) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableVibration: enabled);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置震动为 $enabled');
    return updatedPrefs;
  }

  /// 设置声音反馈
  Future<UserPreferences> setSound(bool enabled) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableSound: enabled);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置声音为 $enabled');
    return updatedPrefs;
  }

  /// 设置缓存限制
  Future<UserPreferences> setCacheLimit(int limitMB) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(cacheLimit: limitMB);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置缓存限制为 ${limitMB}MB');
    return updatedPrefs;
  }

  /// 设置数据保护模式
  Future<UserPreferences> setDataSaver(bool enabled) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.copyWith(enableDataSaver: enabled);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置数据保护模式为 $enabled');
    return updatedPrefs;
  }

  /// 标记为非首次启动
  Future<UserPreferences> markNotFirstLaunch() async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.markNotFirstLaunch();
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 标记为非首次启动');
    return updatedPrefs;
  }

  /// 标记为已同步
  Future<UserPreferences> markSynced() async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.markSynced();
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 标记为已同步');
    return updatedPrefs;
  }

  /// 设置自定义数据
  Future<UserPreferences> setCustomData(String key, dynamic value) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.setCustomData(key, value);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 设置自定义数据 $key');
    return updatedPrefs;
  }

  /// 获取自定义数据
  Future<T?> getCustomData<T>(String key) async {
    final preferences = await loadPreferences();
    return preferences.getCustomData<T>(key);
  }

  /// 移除自定义数据
  Future<UserPreferences> removeCustomData(String key) async {
    final currentPrefs = await loadPreferences();
    final updatedPrefs = currentPrefs.removeCustomData(key);
    await savePreferences(updatedPrefs);
    AppLogger.debug('UserPreferencesService: 移除自定义数据 $key');
    return updatedPrefs;
  }

  /// 批量更新偏好设置
  Future<UserPreferences> updateMultiplePreferences(
    Map<String, dynamic> updates,
  ) async {
    var currentPrefs = await loadPreferences();

    for (final entry in updates.entries) {
      switch (entry.key) {
        case 'language':
          currentPrefs = currentPrefs.copyWith(language: entry.value);
          break;
        case 'enableNotifications':
          currentPrefs = currentPrefs.copyWith(
            enableNotifications: entry.value,
          );
          break;
        case 'enableVibration':
          currentPrefs = currentPrefs.copyWith(enableVibration: entry.value);
          break;
        case 'enableSound':
          currentPrefs = currentPrefs.copyWith(enableSound: entry.value);
          break;
        case 'cacheLimit':
          currentPrefs = currentPrefs.copyWith(cacheLimit: entry.value);
          break;
        case 'enableDataSaver':
          currentPrefs = currentPrefs.copyWith(enableDataSaver: entry.value);
          break;
        default:
          // 自定义数据
          currentPrefs = currentPrefs.setCustomData(entry.key, entry.value);
      }
    }

    await savePreferences(currentPrefs);
    AppLogger.debug('UserPreferencesService: 批量更新${updates.length}个偏好设置');
    return currentPrefs;
  }

  /// 重置为默认配置
  Future<UserPreferences> resetToDefault() async {
    await savePreferences(UserPreferences.defaultConfig);
    AppLogger.debug('UserPreferencesService: 已重置为默认用户偏好');
    return UserPreferences.defaultConfig;
  }

  /// 检查是否存在配置
  bool hasPreferences() {
    return _prefs.containsKey(_configKey);
  }

  /// 删除配置
  Future<void> deletePreferences() async {
    await _prefs.remove(_configKey);
    AppLogger.debug('UserPreferencesService: 用户偏好已删除');
  }

  // ===== 便利方法 =====

  /// 检查是否首次启动
  Future<bool> isFirstLaunch() async {
    final preferences = await loadPreferences();
    return preferences.isFirstLaunch;
  }

  /// 检查是否需要同步
  Future<bool> needsSync() async {
    final preferences = await loadPreferences();
    return preferences.needsSync;
  }

  /// 获取上次同步时间
  Future<DateTime?> getLastSyncTime() async {
    final preferences = await loadPreferences();
    return preferences.lastSyncTime;
  }

  /// 获取当前语言
  Future<String> getCurrentLanguage() async {
    final preferences = await loadPreferences();
    return preferences.language;
  }

  /// 检查缓存是否接近限制
  Future<bool> isCacheNearLimit(int currentCacheSizeMB) async {
    final preferences = await loadPreferences();
    return preferences.isCacheNearLimit(currentCacheSizeMB);
  }

  /// 获取所有通知和反馈设置
  Future<Map<String, bool>> getNotificationSettings() async {
    final preferences = await loadPreferences();
    return {
      'notifications': preferences.enableNotifications,
      'vibration': preferences.enableVibration,
      'sound': preferences.enableSound,
    };
  }

  /// 获取性能相关设置
  Future<Map<String, dynamic>> getPerformanceSettings() async {
    final preferences = await loadPreferences();
    return {
      'cacheLimit': preferences.cacheLimit,
      'dataSaver': preferences.enableDataSaver,
    };
  }
}
