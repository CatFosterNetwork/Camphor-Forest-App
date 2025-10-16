// lib/core/config/models/theme_config.dart

import 'package:flutter/material.dart';
import '../../models/theme_model.dart' as theme_model;
import '../../utils/theme_utils.dart';

/// 主题配置模型
/// 管理应用主题、深色模式等设置
/// 注意：自定义主题列表不存储在此，通过 CustomThemeService 单独管理
class ThemeConfig {
  /// 主题模式：auto, system, light, dark
  final String themeMode;

  /// 是否为深色模式（当themeMode为light/dark时使用）
  final bool isDarkMode;

  /// 当前选中的主题
  final theme_model.Theme? selectedTheme;

  /// 选中的主题代码
  final String selectedThemeCode;

  const ThemeConfig({
    this.themeMode = 'system',
    this.isDarkMode = false,
    this.selectedTheme,
    this.selectedThemeCode = 'classic-theme-1', // 默认为你好西大人主题
  });

  /// 从JSON创建ThemeConfig
  /// 注意：不处理 customThemes，自定义主题由 CustomThemeService 单独管理
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      themeMode: json['theme-colorMode'] ?? 'system',
      isDarkMode: json['theme-darkMode'] ?? false,
      selectedTheme: json['theme-theme'] != null
          ? theme_model.Theme.fromJson(json['theme-theme'])
          : null,
      selectedThemeCode:
          json['selectedThemeCode'] ?? 'classic-theme-1', // 默认为你好西大人主题
    );
  }

  /// 转换为JSON
  /// 注意：不包含 customThemes，由上传逻辑动态添加
  Map<String, dynamic> toJson() {
    return {
      'theme-colorMode': themeMode,
      'theme-darkMode': isDarkMode,
      'theme-theme': selectedTheme?.toJson(),
      'selectedThemeCode': selectedThemeCode,
    };
  }

  /// 复制并修改配置
  ThemeConfig copyWith({
    String? themeMode,
    bool? isDarkMode,
    theme_model.Theme? selectedTheme,
    String? selectedThemeCode,
    bool clearSelectedTheme = false,
  }) {
    return ThemeConfig(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedTheme: clearSelectedTheme
          ? null
          : (selectedTheme ?? this.selectedTheme),
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfig &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isDarkMode == other.isDarkMode &&
          selectedTheme == other.selectedTheme &&
          selectedThemeCode == other.selectedThemeCode;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      isDarkMode.hashCode ^
      selectedTheme.hashCode ^
      selectedThemeCode.hashCode;

  @override
  String toString() {
    return 'ThemeConfig{themeMode: $themeMode, isDarkMode: $isDarkMode, selectedThemeCode: $selectedThemeCode, isCustom: $isUsingCustomTheme}';
  }
}
