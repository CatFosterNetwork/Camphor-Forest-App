// lib/core/config/services/theme_config_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theme_config.dart';
import '../../models/theme_model.dart';
import '../../services/custom_theme_service.dart';
import '../../utils/theme_utils.dart';

/// 主题配置服务
/// 负责主题配置的加载、保存和管理
class ThemeConfigService {
  static const String _configKey = 'theme_config';

  final SharedPreferences _prefs;
  final CustomThemeService _customThemeService;

  /// 内存缓存，减少磁盘读取
  ThemeConfig? _cachedConfig;

  ThemeConfigService(this._prefs, this._customThemeService);

  /// 加载主题配置
  /// [forceRefresh] 为 true 时强制从磁盘重新加载
  Future<ThemeConfig> loadConfig({bool forceRefresh = false}) async {
    try {
      // 如果有缓存且不强制刷新，直接返回缓存
      if (_cachedConfig != null && !forceRefresh) {
        debugPrint('ThemeConfigService: 从缓存加载主题配置');
        return _cachedConfig!;
      }

      debugPrint('ThemeConfigService: 开始从磁盘加载主题配置...');

      // 首先尝试加载新格式的配置
      final configJson = _prefs.getString(_configKey);
      debugPrint('ThemeConfigService: 新格式配置数据: $configJson');

      if (configJson != null) {
        final config = ThemeConfig.fromJson(jsonDecode(configJson));
        _cachedConfig = config; // 更新缓存
        debugPrint(
          'ThemeConfigService: 成功加载主题配置 - 深色模式: ${config.isDarkMode}, 主题模式: ${config.themeMode}',
        );
        return config;
      }

      debugPrint('ThemeConfigService: 新格式配置不存在，使用默认配置');
      // 如果新配置不存在，使用默认配置并保存
      const defaultConfig = ThemeConfig.defaultConfig;
      await saveConfig(defaultConfig);
      debugPrint('ThemeConfigService: 已保存默认主题配置');
      return defaultConfig;
    } catch (e) {
      debugPrint('ThemeConfigService: 加载主题配置失败，使用默认配置: $e');
      // 清除无效缓存
      _cachedConfig = null;
      return ThemeConfig.defaultConfig;
    }
  }

  /// 保存主题配置
  Future<void> saveConfig(ThemeConfig config) async {
    try {
      _cachedConfig = config; // 先更新缓存

      final configJson = jsonEncode(config.toJson());
      debugPrint('ThemeConfigService: 准备保存主题配置: $configJson');

      final success = await _prefs.setString(_configKey, configJson);
      debugPrint(
        'ThemeConfigService: SharedPreferences.setString 返回值: $success',
      );

      // 立即验证保存是否成功
      final savedConfig = _prefs.getString(_configKey);
      if (savedConfig == configJson) {
        debugPrint('ThemeConfigService: 主题配置保存成功，验证通过（已更新缓存）');
      } else {
        debugPrint('ThemeConfigService: 警告 - 保存的配置验证失败');
        debugPrint('  期望: $configJson');
        debugPrint('  实际: $savedConfig');
        _cachedConfig = null; // 验证失败时清除缓存
      }
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

    Theme? finalTheme = theme;

    // 如果没有提供主题对象，尝试查找
    if (finalTheme == null) {
      if (ThemeUtils.isCustomTheme(themeCode)) {
        // 从 CustomThemeService 单一数据源查找
        final customThemes = await _customThemeService.getCustomThemes();
        try {
          finalTheme = customThemes.firstWhere((t) => t.code == themeCode);
          debugPrint(
            'ThemeConfigService: 从 CustomThemeService 查找自定义主题 $themeCode: 找到',
          );
        } catch (e) {
          debugPrint(
            'ThemeConfigService: 从 CustomThemeService 查找自定义主题 $themeCode: 未找到',
          );
        }
      }
    }

    // 如果是自定义主题且提供了主题对象，保存到 CustomThemeService
    if (finalTheme != null && ThemeUtils.isCustomTheme(themeCode)) {
      await _customThemeService.saveCustomTheme(finalTheme);
      debugPrint(
        'ThemeConfigService: 已保存自定义主题到 CustomThemeService: ${finalTheme.title}',
      );
    }

    // 统一更新配置
    final updatedConfig = currentConfig.copyWith(
      selectedThemeCode: themeCode,
      selectedTheme: finalTheme,
      clearSelectedTheme: finalTheme == null,
    );

    await saveConfig(updatedConfig);

    debugPrint(
      'ThemeConfigService: ✅ 选择主题完成 - '
      'code: $themeCode, '
      'selectedTheme: ${finalTheme?.title ?? "null"}, '
      'isCustom: ${!themeCode.startsWith("classic-theme-")}',
    );

    return updatedConfig;
  }

  /// 设置自定义主题（添加或更新）
  Future<ThemeConfig> setCustomTheme(Theme customTheme) async {
    final currentConfig = await loadConfig();

    // 保存到 CustomThemeService（单一数据源）
    await _customThemeService.saveCustomTheme(customTheme);

    // 更新配置
    final updatedConfig = currentConfig.copyWith(
      selectedThemeCode: customTheme.code,
      clearSelectedTheme: true, // 清除预设主题
    );
    await saveConfig(updatedConfig);
    debugPrint('ThemeConfigService: 设置自定义主题 ${customTheme.code}');
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
    final config = await loadConfig();

    // 如果是自定义主题，从 CustomThemeService 单一数据源查找
    if (ThemeUtils.isCustomTheme(themeCode)) {
      final customThemes = await _customThemeService.getCustomThemes();
      try {
        return customThemes.firstWhere((t) => t.code == themeCode);
      } catch (e) {
        return null;
      }
    }

    // 如果是当前选中的主题，直接返回
    if (themeCode == config.selectedThemeCode) {
      return config.selectedTheme;
    }

    // 从主题列表中查找
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

    // 如果使用自定义主题，从 CustomThemeService 获取
    if (config.isUsingCustomTheme) {
      final customThemes = await _customThemeService.getCustomThemes();
      try {
        return customThemes.firstWhere(
          (t) => t.code == config.selectedThemeCode,
        );
      } catch (e) {
        debugPrint('ThemeConfigService: 未找到自定义主题 ${config.selectedThemeCode}');
        return null;
      }
    }

    // 如果使用预设主题，直接返回 selectedTheme
    return config.selectedTheme;
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
