// lib/core/config/services/app_config_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

/// 应用配置服务
/// 负责应用功能配置的加载、保存和管理
class AppConfigService {
  static const String _configKey = 'app_config';
  static const String _legacyConfigKey = 'config'; // 用于迁移旧配置
  
  final SharedPreferences _prefs;

  AppConfigService(this._prefs);

  /// 加载应用配置
  Future<AppConfig> loadConfig() async {
    try {
      // 首先尝试加载新格式的配置
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        final config = AppConfig.fromJson(jsonDecode(configJson));
        debugPrint('AppConfigService: 成功加载应用配置');
        return config;
      }
      
      // 如果新配置不存在，尝试从旧配置迁移
      return await _migrateFromLegacyConfig();
    } catch (e) {
      debugPrint('AppConfigService: 加载应用配置失败，使用默认配置: $e');
      return AppConfig.defaultConfig;
    }
  }

  /// 保存应用配置
  Future<void> saveConfig(AppConfig config) async {
    try {
      final configJson = jsonEncode(config.toJson());
      await _prefs.setString(_configKey, configJson);
      debugPrint('AppConfigService: 应用配置已保存');
    } catch (e) {
      debugPrint('AppConfigService: 保存应用配置失败: $e');
      throw Exception('保存应用配置失败: $e');
    }
  }

  /// 更新单个配置项
  Future<AppConfig> updateConfigItem(String key, bool value) async {
    final currentConfig = await loadConfig();
    final updatedConfig = _updateConfigByKey(currentConfig, key, value);
    await saveConfig(updatedConfig);
    debugPrint('AppConfigService: 更新配置项 $key = $value');
    return updatedConfig;
  }

  /// 批量更新配置项
  Future<AppConfig> updateMultipleItems(Map<String, bool> updates) async {
    var currentConfig = await loadConfig();
    
    for (final entry in updates.entries) {
      currentConfig = _updateConfigByKey(currentConfig, entry.key, entry.value);
    }
    
    await saveConfig(currentConfig);
    debugPrint('AppConfigService: 批量更新${updates.length}个配置项');
    return currentConfig;
  }

  /// 重置为默认配置
  Future<AppConfig> resetToDefault() async {
    await saveConfig(AppConfig.defaultConfig);
    debugPrint('AppConfigService: 已重置为默认配置');
    return AppConfig.defaultConfig;
  }

  /// 检查是否存在配置
  bool hasConfig() {
    return _prefs.containsKey(_configKey);
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    await _prefs.remove(_configKey);
    debugPrint('AppConfigService: 应用配置已删除');
  }

  /// 获取特定类型的配置
  Future<Map<String, bool>> getIndexDisplayConfig() async {
    final config = await loadConfig();
    return config.indexDisplaySettings;
  }

  Future<Map<String, bool>> getForestFeatureConfig() async {
    final config = await loadConfig();
    return config.forestFeatureSettings;
  }

  // ===== 私有方法 =====

  /// 从旧配置迁移
  Future<AppConfig> _migrateFromLegacyConfig() async {
    try {
      final legacyConfigJson = _prefs.getString(_legacyConfigKey);
      if (legacyConfigJson != null) {
        final legacyConfig = jsonDecode(legacyConfigJson) as Map<String, dynamic>;
        
        // 创建新的AppConfig，只提取应用配置相关的字段
        final appConfig = AppConfig.fromJson(legacyConfig);
        
        // 保存到新的存储键
        await saveConfig(appConfig);
        
        debugPrint('AppConfigService: 成功从旧配置迁移应用设置');
        return appConfig;
      }
    } catch (e) {
      debugPrint('AppConfigService: 旧配置迁移失败: $e');
    }
    
    // 如果迁移失败，返回默认配置
    debugPrint('AppConfigService: 使用默认应用配置');
    return AppConfig.defaultConfig;
  }

  /// 根据键更新配置
  AppConfig _updateConfigByKey(AppConfig config, String key, bool value) {
    switch (key) {
      // 首页显示设置
      case 'index-showFinishedTodo':
        return config.copyWith(showFinishedTodo: value);
      case 'index-showTodo':
        return config.copyWith(showTodo: value);
      case 'index-showExpense':
        return config.copyWith(showExpense: value);
      case 'index-showClassroom':
        return config.copyWith(showClassroom: value);
      case 'index-showExams':
        return config.copyWith(showExams: value);
      case 'index-showGrades':
        return config.copyWith(showGrades: value);
      case 'index-showIndexServices':
        return config.copyWith(showIndexServices: value);
        
      // 森林功能设置
      case 'forest-showFleaMarket':
        return config.copyWith(showFleaMarket: value);
      case 'forest-showCampusRecruitment':
        return config.copyWith(showCampusRecruitment: value);
      case 'forest-showSchoolNavigation':
        return config.copyWith(showSchoolNavigation: value);
      case 'forest-showLibrary':
        return config.copyWith(showLibrary: value);
      case 'forest-showBBS':
        return config.copyWith(showBBS: value);
      case 'forest-showAds':
        return config.copyWith(showAds: value);
      case 'forest-showLifeService':
        return config.copyWith(showLifeService: value);
      case 'forest-showFeedback':
        return config.copyWith(showFeedback: value);
        
      // 应用基础设置
      case 'autoSync':
        return config.copyWith(autoSync: value);
      case 'autoRenewalCheckInService':
        return config.copyWith(autoRenewalCheckInService: value);
        
      default:
        debugPrint('AppConfigService: 未知的配置键: $key');
        return config;
    }
  }

  // ===== 便利方法 =====

  /// 检查特定森林功能是否启用
  Future<bool> isForestFeatureEnabled(String featureAbbr) async {
    final config = await loadConfig();
    final key = 'forest-show$featureAbbr';
    
    switch (key) {
      case 'forest-showFleaMarket':
        return config.showFleaMarket;
      case 'forest-showCampusRecruitment':
        return config.showCampusRecruitment;
      case 'forest-showSchoolNavigation':
        return config.showSchoolNavigation;
      case 'forest-showLibrary':
        return config.showLibrary;
      case 'forest-showBBS':
        return config.showBBS;
      case 'forest-showAds':
        return config.showAds;
      case 'forest-showLifeService':
        return config.showLifeService;
      case 'forest-showFeedback':
        return config.showFeedback;
      default:
        return false;
    }
  }

  /// 检查特定首页功能是否启用
  Future<bool> isIndexFeatureEnabled(String featureKey) async {
    final config = await loadConfig();
    
    switch (featureKey) {
      case 'index-showFinishedTodo':
        return config.showFinishedTodo;
      case 'index-showTodo':
        return config.showTodo;
      case 'index-showExpense':
        return config.showExpense;
      case 'index-showClassroom':
        return config.showClassroom;
      case 'index-showExams':
        return config.showExams;
      case 'index-showGrades':
        return config.showGrades;
      case 'index-showIndexServices':
        return config.showIndexServices;
      default:
        return false;
    }
  }
}