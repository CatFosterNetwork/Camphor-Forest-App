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
import '../../services/api_service.dart';

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
  final CustomThemeService _customThemeService;

  UnifiedConfigService._({
    required SharedPreferences prefs,
    required AppConfigService appConfigService,
    required ThemeConfigService themeConfigService,
    required UserPreferencesService userPreferencesService,
    required ConfigSyncService syncService,
    required CustomThemeService customThemeService,
  }) : _prefs = prefs,
       _appConfigService = appConfigService,
       _themeConfigService = themeConfigService,
       _userPreferencesService = userPreferencesService,
       _syncService = syncService,
       _customThemeService = customThemeService;

  /// 工厂构造函数
  static Future<UnifiedConfigService> create(
    SharedPreferences prefs,
    CustomThemeService customThemeService,
    ApiService? apiService,
  ) async {
    final appConfigService = AppConfigService(prefs);
    final themeConfigService = ThemeConfigService(prefs, customThemeService);
    final userPreferencesService = UserPreferencesService(prefs);
    final syncService = ConfigSyncService(apiService: apiService);

    return UnifiedConfigService._(
      prefs: prefs,
      appConfigService: appConfigService,
      themeConfigService: themeConfigService,
      userPreferencesService: userPreferencesService,
      syncService: syncService,
      customThemeService: customThemeService,
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
  Future<ConfigResult> _initializeFromApiData(
    Map<String, dynamic> apiData,
  ) async {
    final repairedData = ApiConfigDistributor.repairConfigData(apiData);

    // 打印配置统计信息
    final stats = ApiConfigDistributor.getConfigStats(repairedData);
    debugPrint('UnifiedConfigService: 配置统计 - ${stats.toString()}');

    final distributionResult = ApiConfigDistributor.distributeApiData(
      repairedData,
    );
    if (!distributionResult.success) {
      return ConfigResult.failure(
        distributionResult.error ?? Exception('API数据分配失败'),
        distributionResult.stackTrace ?? StackTrace.current,
      );
    }

    // 保存自定义主题到 CustomThemeService
    final themeConfig = distributionResult.themeConfig!;

    // 过滤掉预设主题，只保留真正的自定义主题
    final realCustomThemes = themeConfig.customThemes.where((theme) {
      if (theme.isPreset) {
        debugPrint(
          'UnifiedConfigService: ⚠️ 检测到预设主题 ${theme.code}，已跳过保存（预设主题应从 assets 加载）',
        );
      }
      return theme.isCustom;
    }).toList();

    // 使用 replaceAllCustomThemes 替换整个列表
    try {
      await _customThemeService.replaceAllCustomThemes(realCustomThemes);
      debugPrint(
        'UnifiedConfigService: 已替换所有自定义主题，共 ${realCustomThemes.length} 个',
      );
      if (realCustomThemes.isNotEmpty) {
        for (final theme in realCustomThemes) {
          debugPrint('  - ${theme.title} (${theme.code})');
        }
      } else {
        debugPrint('  - 服务器配置中没有自定义主题，已清空本地自定义主题');
      }
    } catch (e) {
      debugPrint('UnifiedConfigService: 替换自定义主题失败: $e');
    }

    await Future.wait([
      _appConfigService.saveConfig(distributionResult.appConfig!),
      _themeConfigService.saveConfig(distributionResult.themeConfig!),
      _userPreferencesService.savePreferences(
        distributionResult.userPreferences!,
      ),
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
      _userPreferencesService.savePreferences(
        distributionResult.userPreferences!,
      ),
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
  /// 使用嵌套格式，上传后自动更新本地配置（图片URL）
  Future<bool> syncToServer() async {
    try {
      final allConfigs = await getAllConfigs();

      // 使用嵌套格式
      final nestedSyncData = <String, dynamic>{
        'appConfig': allConfigs.appConfig.toJson(),
        'themeConfig': allConfigs.themeConfig.toJson(),
        'userPreferences': allConfigs.userPreferences.toJson(),
      };

      // 确保 selectedThemeCode 在 themeConfig 中
      if (!nestedSyncData['themeConfig'].containsKey('selectedThemeCode')) {
        nestedSyncData['themeConfig']['selectedThemeCode'] =
            allConfigs.themeConfig.selectedThemeCode;
      }

      // 删除 autoSync 字段（不同步到服务器）
      nestedSyncData['appConfig'].remove('autoSync');

      // 添加版本标记，方便后续识别数据来源
      nestedSyncData['_configVersion'] = '2.0';
      nestedSyncData['_uploadSource'] = 'flutter';
      nestedSyncData['_uploadTime'] = DateTime.now().toIso8601String();

      // 上传配置，返回处理后的数据（图片URL已替换）
      final processedData = await _syncService.uploadConfigs(nestedSyncData);

      // 将上传后的配置（包含图片URL）更新回本地
      if (processedData['themeConfig'] != null) {
        final updatedThemeConfig = ThemeConfig.fromJson(
          processedData['themeConfig'] as Map<String, dynamic>,
        );
        await _themeConfigService.saveConfig(updatedThemeConfig);
        debugPrint('UnifiedConfigService: 已更新本地主题配置（图片URL）');

        // 同步更新自定义主题到 CustomThemeService
        final realCustomThemes = updatedThemeConfig.customThemes.where((theme) {
          return theme.isCustom;
        }).toList();
        await _customThemeService.replaceAllCustomThemes(realCustomThemes);
        debugPrint('UnifiedConfigService: 已更新本地自定义主题列表（图片URL）');
      }

      await _userPreferencesService.markSynced();
      debugPrint('UnifiedConfigService: 配置同步到服务器成功（嵌套格式）');
      return true;
    } catch (e) {
      debugPrint('UnifiedConfigService: 配置同步失败: $e');
      return false;
    }
  }

  /// 检查本地配置是否已修改（与默认配置不同）
  Future<bool> hasLocalConfigChanges() async {
    try {
      final currentConfigs = await getAllConfigs();
      final defaultConfigs = ApiConfigDistributor.createDefaultConfigs();

      // 检查 AppConfig
      final appConfigChanged =
          currentConfigs.appConfig != defaultConfigs.appConfig;

      // 检查 ThemeConfig (selectedThemeCode 是关键指标)
      final themeConfigChanged =
          currentConfigs.themeConfig.selectedThemeCode !=
          defaultConfigs.themeConfig!.selectedThemeCode;

      // 不再检查自定义主题
      // 理由：
      // 1. 如果用户创建了自定义主题并选择了它，selectedThemeCode 会变化
      // 2. 如果用户只是创建了主题但没选择，这不算"重要修改"
      // 3. 下载配置时应该完全替换本地自定义主题

      final hasChanges = appConfigChanged || themeConfigChanged;

      debugPrint(
        'UnifiedConfigService: 本地配置检查 - '
        'AppConfig已修改: $appConfigChanged, '
        'ThemeConfig已修改: $themeConfigChanged, '
        '总结: ${hasChanges ? "有修改" : "无修改"}',
      );

      return hasChanges;
    } catch (e) {
      debugPrint('UnifiedConfigService: 检查本地配置失败: $e');
      return false; // 出错时假定无修改，允许下载
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
      await _prefs.setInt(
        '${_lastApiDataKey}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
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
    await _prefs.setInt(
      '${_configSourceKey}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
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
      return {'status': 'error', 'error': e.toString()};
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
