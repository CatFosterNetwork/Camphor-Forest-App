// lib/core/config/services/unified_config_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/theme_config.dart';
import '../models/user_preferences.dart';
import '../data/api_config_distributor.dart';
import 'app_config_service.dart';
import 'theme_config_service.dart';
import 'user_preferences_service.dart';
import 'config_sync_service.dart';
import '../../services/custom_theme_service.dart';

/// 统一配置服务
/// 合并了 ConfigManager + ConfigInitializationService 的功能
/// 提供配置的初始化、管理、缓存等所有核心功能
class UnifiedConfigService {
  static const String _lastApiDataKey = 'last_api_config_data';
  static const String _configSourceKey = 'config_source';

  final SharedPreferences _prefs;
  final AppConfigService _appConfigService;
  final ThemeConfigService _themeConfigService;
  final UserPreferencesService _userPreferencesService;
  final ConfigSyncService _syncService;

  UnifiedConfigService._({
    required SharedPreferences prefs,
    required AppConfigService appConfigService,
    required ThemeConfigService themeConfigService,
    required UserPreferencesService userPreferencesService,
    required ConfigSyncService syncService,
  })  : _prefs = prefs,
        _appConfigService = appConfigService,
        _themeConfigService = themeConfigService,
        _userPreferencesService = userPreferencesService,
        _syncService = syncService;

  /// 工厂构造函数
  static Future<UnifiedConfigService> create(
    SharedPreferences prefs,
    CustomThemeService customThemeService,
  ) async {
    final appConfigService = AppConfigService(prefs);
    final themeConfigService = ThemeConfigService(prefs, customThemeService);
    final userPreferencesService = UserPreferencesService(prefs);
    final syncService = ConfigSyncService();

    return UnifiedConfigService._(
      prefs: prefs,
      appConfigService: appConfigService,
      themeConfigService: themeConfigService,
      userPreferencesService: userPreferencesService,
      syncService: syncService,
    );
  }

  // ===== 初始化功能 (从 ConfigInitializationService 迁移) =====

  /// 智能初始化配置系统
  /// 优先级: API数据 → 缓存数据 → 默认配置
  Future<ConfigResult> initialize({Map<String, dynamic>? apiData}) async {
    try {
      debugPrint('UnifiedConfigService: 开始配置初始化...');

      Map<String, dynamic>? dataToUse;
      String dataSource;

      if (apiData != null && apiData.isNotEmpty) {
        // 使用新的API数据
        dataToUse = apiData;
        dataSource = 'api_fresh';
        await _cacheApiData(apiData);
      } else {
        // 尝试使用缓存数据
        final cachedData = await _getCachedApiData();
        if (cachedData != null && cachedData.isNotEmpty) {
          dataToUse = cachedData;
          dataSource = 'api_cached';
        } else {
          dataSource = 'defaults';
        }
      }

      // 根据数据源初始化
      ConfigResult result;
      if (dataToUse != null) {
        if (_validateApiData(dataToUse)) {
          result = await _initializeFromApiData(dataToUse);
        } else {
          result = await _initializeWithDefaults();
          dataSource = 'defaults_fallback';
        }
      } else {
        result = await _initializeWithDefaults();
      }

      await _recordConfigSource(dataSource);
      debugPrint('UnifiedConfigService: 配置初始化完成 (来源: $dataSource)');

      return result;
    } catch (e, st) {
      debugPrint('UnifiedConfigService: 配置初始化失败: $e');
      return ConfigResult.failure(e, st);
    }
  }

  /// 从API数据初始化
  Future<ConfigResult> _initializeFromApiData(Map<String, dynamic> apiData) async {
    final distributionResult = ApiConfigDistributor.distributeApiData(apiData);
    if (!distributionResult.success) {
      return ConfigResult.failure(
        distributionResult.error ?? Exception('API数据分配失败'),
        distributionResult.stackTrace ?? StackTrace.current,
      );
    }

    await Future.wait([
      _appConfigService.saveConfig(distributionResult.appConfig!),
      _themeConfigService.saveConfig(distributionResult.themeConfig!),
      _userPreferencesService.savePreferences(distributionResult.userPreferences!),
    ]);

    return ConfigResult.success(
      appConfig: distributionResult.appConfig!,
      themeConfig: distributionResult.themeConfig!,
      userPreferences: distributionResult.userPreferences!,
    );
  }

  /// 使用默认配置初始化
  Future<ConfigResult> _initializeWithDefaults() async {
    final distributionResult = ApiConfigDistributor.createDefaultConfigs();

    await Future.wait([
      _appConfigService.saveConfig(distributionResult.appConfig!),
      _themeConfigService.saveConfig(distributionResult.themeConfig!),
      _userPreferencesService.savePreferences(distributionResult.userPreferences!),
    ]);

    return ConfigResult.success(
      appConfig: distributionResult.appConfig!,
      themeConfig: distributionResult.themeConfig!,
      userPreferences: distributionResult.userPreferences!,
    );
  }

  // ===== 配置管理功能 (从 ConfigManager 迁移) =====

  /// 获取所有配置
  Future<AllConfigs> getAllConfigs() async {
    final results = await Future.wait([
      _appConfigService.loadConfig(),
      _themeConfigService.loadConfig(),
      _userPreferencesService.loadPreferences(),
    ]);

    return AllConfigs(
      appConfig: results[0] as AppConfig,
      themeConfig: results[1] as ThemeConfig,
      userPreferences: results[2] as UserPreferences,
    );
  }

  /// 更新应用配置
  Future<AppConfig> updateAppConfig(Map<String, dynamic> updates) async {
    final updateData = <String, bool>{};
    for (final entry in updates.entries) {
      if (entry.value is bool) {
        updateData[entry.key] = entry.value;
      }
    }
    return await _appConfigService.updateMultipleItems(updateData);
  }

  /// 更新主题配置  
  Future<ThemeConfig> updateThemeConfig(Map<String, dynamic> updates) async {
    if (updates.containsKey('themeMode')) {
      return await _themeConfigService.setThemeMode(updates['themeMode']);
    }
    if (updates.containsKey('isDarkMode')) {
      return await _themeConfigService.setDarkMode(updates['isDarkMode']);
    }
    // 其他主题更新逻辑...
    return await _themeConfigService.loadConfig();
  }

  /// 重置所有配置
  Future<ConfigResult> resetAllConfigs() async {
    try {
      final results = await Future.wait([
        _appConfigService.resetToDefault(),
        _themeConfigService.resetToDefault(),
        _userPreferencesService.resetToDefault(),
      ]);

      await _recordConfigSource('reset_all');

      return ConfigResult.success(
        appConfig: results[0] as AppConfig,
        themeConfig: results[1] as ThemeConfig,
        userPreferences: results[2] as UserPreferences,
      );
    } catch (e, st) {
      return ConfigResult.failure(e, st);
    }
  }

  // ===== 网络同步功能 =====

  /// 上传配置到服务器
  Future<bool> syncToServer() async {
    try {
      final allConfigs = await getAllConfigs();
      final syncData = {
        'appConfig': allConfigs.appConfig.toJson(),
        'themeConfig': allConfigs.themeConfig.toJson(),
        'userPreferences': allConfigs.userPreferences.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _syncService.uploadConfigs(syncData);
      await _userPreferencesService.markSynced();
      debugPrint('UnifiedConfigService: 配置同步到服务器成功');
      return true;
    } catch (e) {
      debugPrint('UnifiedConfigService: 配置同步失败: $e');
      return false;
    }
  }

  /// 从服务器下载配置
  Future<ConfigResult> syncFromServer() async {
    try {
      final serverData = await _syncService.downloadConfigs();
      if (serverData.isNotEmpty) {
        return await _initializeFromApiData(serverData);
      } else {
        return await _initializeWithDefaults();
      }
    } catch (e, st) {
      debugPrint('UnifiedConfigService: 从服务器下载配置失败: $e');
      return ConfigResult.failure(e, st);
    }
  }

  // ===== 缓存和工具方法 =====

  /// 缓存API数据
  Future<void> _cacheApiData(Map<String, dynamic> apiData) async {
    try {
      final jsonData = jsonEncode(apiData);
      await _prefs.setString(_lastApiDataKey, jsonData);
      await _prefs.setInt('${_lastApiDataKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('UnifiedConfigService: 缓存API数据失败: $e');
    }
  }

  /// 获取缓存的API数据
  Future<Map<String, dynamic>?> _getCachedApiData() async {
    try {
      final jsonData = _prefs.getString(_lastApiDataKey);
      if (jsonData == null) return null;
      return Map<String, dynamic>.from(jsonDecode(jsonData));
    } catch (e) {
      debugPrint('UnifiedConfigService: 获取缓存数据失败: $e');
      return null;
    }
  }

  /// 验证API数据
  bool _validateApiData(Map<String, dynamic> apiData) {
    return ApiConfigDistributor.validateApiData(apiData);
  }

  /// 记录配置来源
  Future<void> _recordConfigSource(String source) async {
    await _prefs.setString(_configSourceKey, source);
    await _prefs.setInt('${_configSourceKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 获取配置来源信息
  Future<Map<String, dynamic>> getConfigSourceInfo() async {
    final source = _prefs.getString(_configSourceKey) ?? 'unknown';
    final cacheTime = _prefs.getInt('${_lastApiDataKey}_timestamp');

    return {
      'source': source,
      'cacheTimestamp': cacheTime,
      'cacheAge': cacheTime != null 
          ? DateTime.now().millisecondsSinceEpoch - cacheTime 
          : null,
    };
  }

  /// 获取配置健康状态
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      return {
        'status': 'healthy',
        'configFiles': {
          'appConfig': _appConfigService.hasConfig(),
          'themeConfig': _themeConfigService.hasConfig(),
          'userPreferences': _userPreferencesService.hasPreferences(),
        },
        'source': await getConfigSourceInfo(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    await _prefs.remove(_lastApiDataKey);
    await _prefs.remove('${_lastApiDataKey}_timestamp');
    debugPrint('UnifiedConfigService: 缓存已清除');
  }
}

/// 配置操作结果
class ConfigResult {
  final bool success;
  final String message;
  final AppConfig? appConfig;
  final ThemeConfig? themeConfig;
  final UserPreferences? userPreferences;
  final Object? error;
  final StackTrace? stackTrace;

  const ConfigResult._({
    required this.success,
    required this.message,
    this.appConfig,
    this.themeConfig,
    this.userPreferences,
    this.error,
    this.stackTrace,
  });

  factory ConfigResult.success({
    required AppConfig appConfig,
    required ThemeConfig themeConfig,
    required UserPreferences userPreferences,
  }) {
    return ConfigResult._(
      success: true,
      message: '操作成功',
      appConfig: appConfig,
      themeConfig: themeConfig,
      userPreferences: userPreferences,
    );
  }

  factory ConfigResult.failure(Object error, StackTrace stackTrace) {
    return ConfigResult._(
      success: false,
      message: '操作失败: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// 所有配置的集合
class AllConfigs {
  final AppConfig appConfig;
  final ThemeConfig themeConfig;
  final UserPreferences userPreferences;

  const AllConfigs({
    required this.appConfig,
    required this.themeConfig,
    required this.userPreferences,
  });

  Map<String, dynamic> toJson() => {
    'appConfig': appConfig.toJson(),
    'themeConfig': themeConfig.toJson(),
    'userPreferences': userPreferences.toJson(),
  };
}