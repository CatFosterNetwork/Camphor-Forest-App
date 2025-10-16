// lib/core/config/models/theme_config.dart

import 'package:flutter/material.dart';
import '../../models/theme_model.dart' as theme_model;
import '../../utils/theme_utils.dart';

/// 主题配置模型
/// 管理应用主题、深色模式、自定义主题等设置
class ThemeConfig {
  /// 主题模式：auto, system, light, dark
  final String themeMode;

  /// 是否为深色模式（当themeMode为light/dark时使用）
  final bool isDarkMode;

  /// 当前选中的主题
  final theme_model.Theme? selectedTheme;

  /// 自定义主题列表
  final List<theme_model.Theme> customThemes;

  /// 选中的主题代码
  final String selectedThemeCode;

  const ThemeConfig({
    this.themeMode = 'system',
    this.isDarkMode = false,
    this.selectedTheme,
    this.customThemes = const [],
    this.selectedThemeCode = 'classic-theme-1', // 默认为你好西大人主题
  });

  /// 从JSON创建ThemeConfig
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    // 解析自定义主题列表（支持新旧两种格式）
    List<theme_model.Theme> customThemes = [];

    if (json['theme-customThemes'] != null &&
        json['theme-customThemes'] is List) {
      customThemes = (json['theme-customThemes'] as List)
          .map(
            (themeJson) =>
                theme_model.Theme.fromJson(themeJson as Map<String, dynamic>),
          )
          .toList();
    }
    // 旧格式：theme-customTheme（单个对象）- 向后兼容
    else if (json['theme-customTheme'] != null) {
      customThemes = [theme_model.Theme.fromJson(json['theme-customTheme'])];
    }

    return ThemeConfig(
      themeMode: json['theme-colorMode'] ?? 'system',
      isDarkMode: json['theme-darkMode'] ?? false,
      selectedTheme: json['theme-theme'] != null
          ? theme_model.Theme.fromJson(json['theme-theme'])
          : null,
      customThemes: customThemes,
      selectedThemeCode:
          json['selectedThemeCode'] ?? 'classic-theme-1', // 默认为你好西大人主题
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'theme-colorMode': themeMode,
      'theme-darkMode': isDarkMode,
      'theme-theme': selectedTheme?.toJson(),
      'theme-customThemes': customThemes
          .map((theme) => theme.toJson())
          .toList(),
      'selectedThemeCode': selectedThemeCode,
    };
  }

  /// 复制并修改配置
  ThemeConfig copyWith({
    String? themeMode,
    bool? isDarkMode,
    theme_model.Theme? selectedTheme,
    List<theme_model.Theme>? customThemes,
    String? selectedThemeCode,
    bool clearSelectedTheme = false,
    bool clearCustomThemes = false,
  }) {
    return ThemeConfig(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedTheme: clearSelectedTheme
          ? null
          : (selectedTheme ?? this.selectedTheme),
      customThemes: clearCustomThemes
          ? []
          : (customThemes ?? this.customThemes),
      selectedThemeCode: selectedThemeCode ?? this.selectedThemeCode,
    );
  }

  /// 默认配置
  static const ThemeConfig defaultConfig = ThemeConfig();

  /// 获取有效的深色模式状态
  bool getEffectiveDarkMode() {
    switch (themeMode) {
      case 'light':
        return false;
      case 'dark':
        return true;
      case 'system':
        // 获取系统实际的亮度模式
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark;
      default:
        return isDarkMode;
    }
  }

  /// 检查是否使用自定义主题
  bool get isUsingCustomTheme => ThemeUtils.isCustomTheme(selectedThemeCode);

  /// 获取当前使用的主题
  theme_model.Theme? get currentTheme {
    if (isUsingCustomTheme) {
      // 从自定义主题列表中查找匹配的主题
      try {
        return customThemes.firstWhere(
          (theme) => theme.code == selectedThemeCode,
        );
      } catch (e) {
        // 如果找不到匹配的主题，返回第一个自定义主题（向后兼容）
        return customThemes.isNotEmpty ? customThemes.first : null;
      }
    }
    return selectedTheme;
  }

  /// 根据 code 获取自定义主题
  theme_model.Theme? getCustomThemeByCode(String code) {
    try {
      return customThemes.firstWhere((theme) => theme.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 添加或更新自定义主题
  ThemeConfig addOrUpdateCustomTheme(theme_model.Theme theme) {
    final updatedThemes = List<theme_model.Theme>.from(customThemes);
    final existingIndex = updatedThemes.indexWhere((t) => t.code == theme.code);

    if (existingIndex != -1) {
      updatedThemes[existingIndex] = theme;
    } else {
      updatedThemes.add(theme);
    }

    return copyWith(customThemes: updatedThemes);
  }

  /// 删除自定义主题
  ThemeConfig removeCustomTheme(String themeCode) {
    final updatedThemes = customThemes
        .where((theme) => theme.code != themeCode)
        .toList();

    return copyWith(customThemes: updatedThemes);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfig &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isDarkMode == other.isDarkMode &&
          selectedTheme == other.selectedTheme &&
          _listEquals(customThemes, other.customThemes) &&
          selectedThemeCode == other.selectedThemeCode;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      isDarkMode.hashCode ^
      selectedTheme.hashCode ^
      customThemes.hashCode ^
      selectedThemeCode.hashCode;

  /// 列表相等性检查
  bool _listEquals(List<theme_model.Theme> a, List<theme_model.Theme> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'ThemeConfig{themeMode: $themeMode, isDarkMode: $isDarkMode, selectedThemeCode: $selectedThemeCode, isCustom: $isUsingCustomTheme, customThemesCount: ${customThemes.length}}';
  }
}
