// lib/core/services/custom_theme_service.dart

import 'dart:convert';

import '../../core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';

class CustomThemeService {
  static const String _customThemesKey = 'custom_themes';
  static const String _currentCustomThemeKey = 'current_custom_theme';

  final SharedPreferences _prefs;

  CustomThemeService(this._prefs);

  /// 获取所有自定义主题
  Future<List<Theme>> getCustomThemes() async {
    try {
      final themesJsonString = _prefs.getString(_customThemesKey);
      if (themesJsonString == null) return [];

      final themesList = json.decode(themesJsonString) as List<dynamic>;
      return themesList
          .map((themeJson) => Theme.fromJson(themeJson as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.debug('获取自定义主题失败: $e');
      return [];
    }
  }

  /// 保存自定义主题
  Future<bool> saveCustomTheme(Theme theme) async {
    try {
      final customThemes = await getCustomThemes();

      // 检查是否已存在相同code的主题，如果存在则替换
      final existingIndex = customThemes.indexWhere(
        (t) => t.code == theme.code,
      );
      if (existingIndex != -1) {
        customThemes[existingIndex] = theme;
      } else {
        customThemes.add(theme);
      }

      final themesJsonString = json.encode(
        customThemes.map((t) => t.toJson()).toList(),
      );

      return await _prefs.setString(_customThemesKey, themesJsonString);
    } catch (e) {
      AppLogger.debug('保存自定义主题失败: $e');
      return false;
    }
  }

  /// 删除自定义主题
  Future<bool> deleteCustomTheme(String themeCode) async {
    try {
      final customThemes = await getCustomThemes();
      final filteredThemes = customThemes
          .where((t) => t.code != themeCode)
          .toList();

      final themesJsonString = json.encode(
        filteredThemes.map((t) => t.toJson()).toList(),
      );

      return await _prefs.setString(_customThemesKey, themesJsonString);
    } catch (e) {
      AppLogger.debug('删除自定义主题失败: $e');
      return false;
    }
  }

  /// 获取当前自定义主题
  Future<Theme?> getCurrentCustomTheme() async {
    try {
      final themeJsonString = _prefs.getString(_currentCustomThemeKey);
      if (themeJsonString == null) return null;

      final themeJson = json.decode(themeJsonString) as Map<String, dynamic>;
      return Theme.fromJson(themeJson);
    } catch (e) {
      AppLogger.debug('获取当前自定义主题失败: $e');
      return null;
    }
  }

  /// 设置当前自定义主题
  Future<bool> setCurrentCustomTheme(Theme theme) async {
    try {
      final themeJsonString = json.encode(theme.toJson());
      return await _prefs.setString(_currentCustomThemeKey, themeJsonString);
    } catch (e) {
      AppLogger.debug('设置当前自定义主题失败: $e');
      return false;
    }
  }

  /// 清除当前自定义主题
  Future<bool> clearCurrentCustomTheme() async {
    try {
      return await _prefs.remove(_currentCustomThemeKey);
    } catch (e) {
      AppLogger.debug('清除当前自定义主题失败: $e');
      return false;
    }
  }

  /// 检查主题代码是否已存在
  Future<bool> isThemeCodeExists(String code) async {
    final customThemes = await getCustomThemes();
    return customThemes.any((theme) => theme.code == code);
  }

  /// 生成唯一的主题代码
  Future<String> generateUniqueThemeCode([String? baseName]) async {
    baseName ??= 'custom';
    String code = baseName;
    int counter = 1;

    while (await isThemeCodeExists(code)) {
      code = '${baseName}_$counter';
      counter++;
    }

    return code;
  }

  /// 清空所有自定义主题
  Future<bool> clearAllCustomThemes() async {
    try {
      return await _prefs.remove(_customThemesKey);
    } catch (e) {
      AppLogger.debug('清空所有自定义主题失败: $e');
      return false;
    }
  }

  /// 替换所有自定义主题（用于从服务器下载配置）
  Future<bool> replaceAllCustomThemes(List<Theme> themes) async {
    try {
      AppLogger.debug('CustomThemeService: 准备替换所有自定义主题，共 ${themes.length} 个');

      final themesJsonString = json.encode(
        themes.map((t) => t.toJson()).toList(),
      );

      final result = await _prefs.setString(_customThemesKey, themesJsonString);

      if (result) {
        AppLogger.debug('CustomThemeService: ✅ 自定义主题保存成功');
        // 验证保存结果
        final saved = await getCustomThemes();
        AppLogger.debug('CustomThemeService: 验证读取 - 共 ${saved.length} 个主题');
        for (final theme in saved) {
          AppLogger.debug('  - ${theme.title} (${theme.code})');
        }
      } else {
        AppLogger.debug('CustomThemeService: ❌ 自定义主题保存失败');
      }

      return result;
    } catch (e) {
      AppLogger.debug('CustomThemeService: 替换所有自定义主题失败: $e');
      return false;
    }
  }
}
