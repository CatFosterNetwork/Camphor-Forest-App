// lib/core/config/services/theme_config_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theme_config.dart';
import '../../models/theme_model.dart';
import '../../services/custom_theme_service.dart';

/// 主题配置服务
/// 负责主题配置的加载、保存和管理
class ThemeConfigService {
  static const String _configKey = 'theme_config';
  static const String _legacyConfigKey = 'config';

  final SharedPreferences _prefs;
  final CustomThemeService _customThemeService;

  ThemeConfigService(this._prefs, this._customThemeService);

  /// 加载主题配置
  Future<ThemeConfig> loadConfig() async {
    try {
      // 首先尝试加载新格式的配置
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        final config = ThemeConfig.fromJson(jsonDecode(configJson));
        debugPrint('ThemeConfigService: 成功加载主题配置');
        return config;
      }

      // 如果新配置不存在，尝试从旧配置迁移
      return await _migrateFromLegacyConfig();
    } catch (e) {
      debugPrint('ThemeConfigService: 加载主题配置失败，使用默认配置: $e');
      return ThemeConfig.defaultConfig;
    }
  }

  /// 保存主题配置
  Future<void> saveConfig(ThemeConfig config) async {
    try {
      final configJson = jsonEncode(config.toJson());
      await _prefs.setString(_configKey, configJson);
      debugPrint('ThemeConfigService: 主题配置已保存');
    } catch (e) {
      debugPrint('ThemeConfigService: 保存主题配置失败: $e');
      throw Exception('保存主题配置失败: $e');
    }
  }

  /// 设置主题模式
  Future<ThemeConfig> setThemeMode(String mode) async {
    final currentConfig = await loadConfig();
    final updatedConfig = currentConfig.copyWith(themeMode: mode);
    await saveConfig(updatedConfig);
    debugPrint('ThemeConfigService: 设置主题模式为 $mode');
    return updatedConfig;
  }

  /// 设置深色模式
  Future<ThemeConfig> setDarkMode(bool isDark) async {
    final currentConfig = await loadConfig();
    final updatedConfig = currentConfig.copyWith(isDarkMode: isDark);
    await saveConfig(updatedConfig);
    debugPrint('ThemeConfigService: 设置深色模式为 $isDark');
    return updatedConfig;
  }

  /// 选择主题
  Future<ThemeConfig> selectTheme(String themeCode, Theme? theme) async {
    final currentConfig = await loadConfig();

    // 如果切换到自定义主题
    if (themeCode == 'custom') {
      final updatedConfig = currentConfig.copyWith(
        selectedThemeCode: themeCode,
        clearSelectedTheme: true, // 清除预设主题
      );
      await saveConfig(updatedConfig);
      debugPrint('ThemeConfigService: 选择自定义主题');
      return updatedConfig;
    }

    // 如果切换到预设主题
    final updatedConfig = currentConfig.copyWith(
      selectedThemeCode: themeCode,
      selectedTheme: theme,
      clearCustomTheme: false, // 保留自定义主题但不使用
    );
    await saveConfig(updatedConfig);
    debugPrint('ThemeConfigService: 选择主题 $themeCode (${theme?.title})');
    return updatedConfig;
  }

  /// 设置自定义主题
  Future<ThemeConfig> setCustomTheme(Theme customTheme) async {
    final currentConfig = await loadConfig();
    final updatedConfig = currentConfig.copyWith(
      customTheme: customTheme,
      selectedThemeCode: 'custom',
      clearSelectedTheme: true, // 清除预设主题
    );
    await saveConfig(updatedConfig);
    debugPrint('ThemeConfigService: 设置自定义主题');
    return updatedConfig;
  }

  /// 重置为默认配置
  Future<ThemeConfig> resetToDefault() async {
    await saveConfig(ThemeConfig.defaultConfig);
    debugPrint('ThemeConfigService: 已重置为默认主题配置');
    return ThemeConfig.defaultConfig;
  }

  /// 获取所有可用主题
  Future<List<Theme>> getAllThemes() async {
    try {
      // 暂时返回空列表，等待CustomThemeService实现getAllThemes方法
      return [];
    } catch (e) {
      debugPrint('ThemeConfigService: 获取主题列表失败: $e');
      return [];
    }
  }

  /// 根据主题代码获取主题
  Future<Theme?> getThemeByCode(String themeCode) async {
    if (themeCode == 'custom') {
      final config = await loadConfig();
      return config.customTheme;
    }

    try {
      final themes = await getAllThemes();
      final foundTheme = themes.where((theme) => theme.code == themeCode);
      if (foundTheme.isNotEmpty) {
        return foundTheme.first;
      }
      return themes.isNotEmpty ? themes.first : null;
    } catch (e) {
      debugPrint('ThemeConfigService: 获取主题失败: $e');
      return null;
    }
  }

  /// 保存自定义主题到文件
  Future<void> saveCustomThemeToFile(Theme customTheme) async {
    try {
      await _customThemeService.saveCustomTheme(customTheme);
      debugPrint('ThemeConfigService: 自定义主题已保存到文件');
    } catch (e) {
      debugPrint('ThemeConfigService: 保存自定义主题失败: $e');
      throw Exception('保存自定义主题失败: $e');
    }
  }

  /// 从文件加载自定义主题
  Future<Theme?> loadCustomThemeFromFile() async {
    try {
      // 暂时返回null，等待CustomThemeService实现loadCustomTheme方法
      return null;
    } catch (e) {
      debugPrint('ThemeConfigService: 加载自定义主题失败: $e');
      return null;
    }
  }

  /// 检查是否存在配置
  bool hasConfig() {
    return _prefs.containsKey(_configKey);
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    await _prefs.remove(_configKey);
    debugPrint('ThemeConfigService: 主题配置已删除');
  }

  // ===== 私有方法 =====

  /// 从旧配置迁移
  Future<ThemeConfig> _migrateFromLegacyConfig() async {
    try {
      final legacyConfigJson = _prefs.getString(_legacyConfigKey);
      if (legacyConfigJson != null) {
        final legacyConfig =
            jsonDecode(legacyConfigJson) as Map<String, dynamic>;

        // 创建新的ThemeConfig，只提取主题相关的字段
        final themeConfig = ThemeConfig.fromJson(legacyConfig);

        // 保存到新的存储键
        await saveConfig(themeConfig);

        debugPrint('ThemeConfigService: 成功从旧配置迁移主题设置');
        return themeConfig;
      }
    } catch (e) {
      debugPrint('ThemeConfigService: 旧配置迁移失败: $e');
    }

    // 如果迁移失败，返回默认配置
    debugPrint('ThemeConfigService: 使用默认主题配置');
    return ThemeConfig.defaultConfig;
  }

  // ===== 便利方法 =====

  /// 获取有效的深色模式状态
  Future<bool> getEffectiveDarkMode() async {
    final config = await loadConfig();
    return config.getEffectiveDarkMode();
  }

  /// 检查是否使用自定义主题
  Future<bool> isUsingCustomTheme() async {
    final config = await loadConfig();
    return config.isUsingCustomTheme;
  }

  /// 获取当前使用的主题
  Future<Theme?> getCurrentTheme() async {
    final config = await loadConfig();

    if (config.isUsingCustomTheme) {
      return config.customTheme ?? await loadCustomThemeFromFile();
    }

    if (config.selectedTheme != null) {
      return config.selectedTheme;
    }

    // 根据主题代码获取主题
    return await getThemeByCode(config.selectedThemeCode);
  }

  /// 切换深色/浅色模式
  Future<ThemeConfig> toggleDarkMode() async {
    final config = await loadConfig();
    return await setDarkMode(!config.isDarkMode);
  }

  /// 循环切换主题模式
  Future<ThemeConfig> cycleThemeMode() async {
    final config = await loadConfig();
    String nextMode;

    switch (config.themeMode) {
      case 'system':
        nextMode = 'light';
        break;
      case 'light':
        nextMode = 'dark';
        break;
      case 'dark':
        nextMode = 'system';
        break;
      default:
        nextMode = 'system';
    }

    return await setThemeMode(nextMode);
  }
}
