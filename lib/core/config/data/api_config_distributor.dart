// lib/core/config/data/api_config_distributor.dart

import 'package:flutter/foundation.dart';

import '../models/app_config.dart';
import '../models/theme_config.dart';
import '../models/user_preferences.dart';
import '../../models/theme_model.dart';

/// API配置数据分配器
/// 负责将从API获取的配置数据分配到各个配置管理系统
class ApiConfigDistributor {
  
  /// 将API配置数据分配到各个配置系统
  static ConfigDistributionResult distributeApiData(Map<String, dynamic> apiData) {
    try {
      debugPrint('ApiConfigDistributor: 开始分配API配置数据...');
      
      // 分配应用配置
      final appConfig = _createAppConfig(apiData);
      
      // 分配主题配置
      final themeConfig = _createThemeConfig(apiData);
      
      // 分配用户偏好（如果API中有的话，否则使用默认值）
      final userPreferences = _createUserPreferences(apiData);
      
      debugPrint('ApiConfigDistributor: 配置数据分配完成');
      return ConfigDistributionResult.success(
        appConfig: appConfig,
        themeConfig: themeConfig,
        userPreferences: userPreferences,
      );
      
    } catch (e, st) {
      debugPrint('ApiConfigDistributor: 配置数据分配失败: $e');
      return ConfigDistributionResult.failure(e, st);
    }
  }

  /// 创建应用配置
  static AppConfig _createAppConfig(Map<String, dynamic> apiData) {
    return AppConfig(
      // 首页显示配置
      showFinishedTodo: _getBool(apiData, 'index-showFinishedTodo', true),
      showTodo: _getBool(apiData, 'index-showTodo', true),
      showExpense: _getBool(apiData, 'index-showExpense', true),
      showClassroom: _getBool(apiData, 'index-showClassroom', true),
      showExams: _getBool(apiData, 'index-showExams', true),
      showGrades: _getBool(apiData, 'index-showGrades', true),
      showIndexServices: _getBool(apiData, 'index-showIndexServices', true),
      
      // 森林功能配置
      showFleaMarket: _getBool(apiData, 'forest-showFleaMarket', false),
      showCampusRecruitment: _getBool(apiData, 'forest-showCampusRecruitment', false),
      showSchoolNavigation: _getBool(apiData, 'forest-showSchoolNavigation', true),
      showLibrary: _getBool(apiData, 'forest-showLibrary', false),
      showBBS: _getBool(apiData, 'forest-showBBS', true),
      showAds: _getBool(apiData, 'forest-showAds', false),
      showLifeService: _getBool(apiData, 'forest-showLifeService', true),
      showFeedback: _getBool(apiData, 'forest-showFeedback', true),
      
      // 基础配置
      autoSync: _getBool(apiData, 'autoSync', false),
      autoRenewalCheckInService: _getBool(apiData, 'autoRenewalCheckInService', false),
    );
  }

  /// 创建主题配置
  static ThemeConfig _createThemeConfig(Map<String, dynamic> apiData) {
    // 解析主题数据
    Theme? selectedTheme;
    Theme? customTheme;
    
    // 如果API中有主题数据，解析它
    if (apiData.containsKey('theme-theme') && apiData['theme-theme'] != null) {
      try {
        selectedTheme = Theme.fromJson(apiData['theme-theme']);
      } catch (e) {
        debugPrint('ApiConfigDistributor: 解析选中主题失败: $e');
      }
    }
    
    if (apiData.containsKey('theme-customTheme') && apiData['theme-customTheme'] != null) {
      try {
        customTheme = Theme.fromJson(apiData['theme-customTheme']);
      } catch (e) {
        debugPrint('ApiConfigDistributor: 解析自定义主题失败: $e');
      }
    }
    
    return ThemeConfig(
      themeMode: _getString(apiData, 'theme-colorMode', 'auto'),
      isDarkMode: _getBool(apiData, 'theme-darkMode', false),
      selectedTheme: selectedTheme,
      customTheme: customTheme,
      selectedThemeCode: _getString(apiData, 'selectedThemeCode', 'classic-theme-1'),
    );
  }

  /// 创建用户偏好配置
  static UserPreferences _createUserPreferences(Map<String, dynamic> apiData) {
    // 用户偏好通常不从API获取，使用默认配置
    // 但如果API中有相关数据，也可以设置
    return UserPreferences(
      language: _getString(apiData, 'language', 'zh-CN'),
      enableNotifications: _getBool(apiData, 'enableNotifications', true),
      enableVibration: _getBool(apiData, 'enableVibration', true),
      enableSound: _getBool(apiData, 'enableSound', true),
      cacheLimit: _getInt(apiData, 'cacheLimit', 100),
      enableDataSaver: _getBool(apiData, 'enableDataSaver', false),
      isFirstLaunch: false, // 如果有API数据，说明不是首次启动
      customData: apiData.containsKey('customUserData') 
          ? Map<String, dynamic>.from(apiData['customUserData']) 
          : {},
    );
  }

  /// 创建空的配置（当API数据不可用时）
  static ConfigDistributionResult createDefaultConfigs() {
    debugPrint('ApiConfigDistributor: 创建默认配置');
    return ConfigDistributionResult.success(
      appConfig: AppConfig.defaultConfig,
      themeConfig: ThemeConfig.defaultConfig,
      userPreferences: UserPreferences.defaultConfig,
    );
  }

  /// 验证API数据格式
  static bool validateApiData(Map<String, dynamic> apiData) {
    // 基本验证：检查是否包含关键配置项
    final requiredKeys = [
      'index-showTodo',
      'forest-showBBS',
      'theme-colorMode',
    ];
    
    for (final key in requiredKeys) {
      if (!apiData.containsKey(key)) {
        debugPrint('ApiConfigDistributor: 缺少必要配置项: $key');
        return false;
      }
    }
    
    return true;
  }

  /// 获取配置项统计
  static Map<String, int> getConfigStats(Map<String, dynamic> apiData) {
    int appConfigCount = 0;
    int themeConfigCount = 0;
    int userPrefCount = 0;
    
    for (final key in apiData.keys) {
      if (key.startsWith('index-') || key.startsWith('forest-') || 
          key == 'autoSync' || key == 'autoRenewalCheckInService') {
        appConfigCount++;
      } else if (key.startsWith('theme-') || key == 'selectedThemeCode') {
        themeConfigCount++;
      } else {
        userPrefCount++;
      }
    }
    
    return {
      'appConfig': appConfigCount,
      'themeConfig': themeConfigCount,
      'userPreferences': userPrefCount,
      'total': apiData.length,
    };
  }

  // ===== 辅助方法 =====

  /// 安全获取布尔值
  static bool _getBool(Map<String, dynamic> data, String key, bool defaultValue) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// 安全获取字符串值
  static String _getString(Map<String, dynamic> data, String key, String defaultValue) {
    final value = data[key];
    return value is String ? value : defaultValue;
  }

  /// 安全获取整数值
  static int _getInt(Map<String, dynamic> data, String key, int defaultValue) {
    final value = data[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is double) return value.round();
    return defaultValue;
  }


}

/// 配置分配结果
class ConfigDistributionResult {
  final bool success;
  final String message;
  final AppConfig? appConfig;
  final ThemeConfig? themeConfig;
  final UserPreferences? userPreferences;
  final Object? error;
  final StackTrace? stackTrace;

  const ConfigDistributionResult._({
    required this.success,
    required this.message,
    this.appConfig,
    this.themeConfig,
    this.userPreferences,
    this.error,  
    this.stackTrace,
  });

  /// 成功的分配结果
  factory ConfigDistributionResult.success({
    required AppConfig appConfig,
    required ThemeConfig themeConfig,
    required UserPreferences userPreferences,
  }) {
    return ConfigDistributionResult._(
      success: true,
      message: '配置数据分配成功',
      appConfig: appConfig,
      themeConfig: themeConfig,
      userPreferences: userPreferences,
    );
  }

  /// 失败的分配结果
  factory ConfigDistributionResult.failure(Object error, StackTrace stackTrace) {
    return ConfigDistributionResult._(
      success: false,
      message: '配置数据分配失败: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'ConfigDistributionResult{success: $success, message: $message}';
  }
}