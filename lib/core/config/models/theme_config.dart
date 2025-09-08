// lib/core/config/models/theme_config.dart

import 'package:flutter/material.dart';
import '../../models/theme_model.dart' as theme_model;

/// 主题配置模型
/// 管理应用主题、深色模式、自定义主题等设置
class ThemeConfig {
  /// 主题模式：auto, system, light, dark
  final String themeMode;

  /// 是否为深色模式（当themeMode为light/dark时使用）
  final bool isDarkMode;

  /// 当前选中的主题
  final theme_model.Theme? selectedTheme;

  /// 自定义主题
  final theme_model.Theme? customTheme;

  /// 选中的主题代码
  final String selectedThemeCode;

  const ThemeConfig({
    this.themeMode = 'system',
    this.isDarkMode = false,
    this.selectedTheme,
    this.customTheme,
    this.selectedThemeCode = 'classic-theme-1', // 默认为你好西大人主题
  });

  /// 从JSON创建ThemeConfig
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      themeMode: json['theme-colorMode'] ?? 'system',
      isDarkMode: json['theme-darkMode'] ?? false,
      selectedTheme: json['theme-theme'] != null
          ? theme_model.Theme.fromJson(json['theme-theme'])
          : null,
      customTheme: json['theme-customTheme'] != null
          ? theme_model.Theme.fromJson(json['theme-customTheme'])
          : null,
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
      'theme-customTheme': customTheme?.toJson(),
      'selectedThemeCode': selectedThemeCode,
    };
  }

  /// 复制并修改配置
  ThemeConfig copyWith({
    String? themeMode,
    bool? isDarkMode,
    theme_model.Theme? selectedTheme,
    theme_model.Theme? customTheme,
    String? selectedThemeCode,
    bool clearSelectedTheme = false,
    bool clearCustomTheme = false,
  }) {
    return ThemeConfig(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedTheme: clearSelectedTheme
          ? null
          : (selectedTheme ?? this.selectedTheme),
      customTheme: clearCustomTheme ? null : (customTheme ?? this.customTheme),
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
  bool get isUsingCustomTheme => selectedThemeCode == 'custom';

  /// 获取当前使用的主题
  theme_model.Theme? get currentTheme {
    if (isUsingCustomTheme) {
      return customTheme;
    }
    return selectedTheme;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfig &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isDarkMode == other.isDarkMode &&
          selectedTheme == other.selectedTheme &&
          customTheme == other.customTheme &&
          selectedThemeCode == other.selectedThemeCode;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      isDarkMode.hashCode ^
      selectedTheme.hashCode ^
      customTheme.hashCode ^
      selectedThemeCode.hashCode;

  @override
  String toString() {
    return 'ThemeConfig{themeMode: $themeMode, isDarkMode: $isDarkMode, selectedThemeCode: $selectedThemeCode, isCustom: $isUsingCustomTheme}';
  }
}
