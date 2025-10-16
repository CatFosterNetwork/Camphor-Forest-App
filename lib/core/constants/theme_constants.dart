/// 主题相关常量
class ThemeConstants {
  // 预设主题代码
  static const String defaultThemeCode = 'classic-theme-1';
  static const String classicTheme2 = 'classic-theme-2';
  static const String classicTheme3 = 'classic-theme-3';

  // 颜色模式（对应 ThemeConfig.themeMode 字段，在 API 中映射为 theme-colorMode）
  // 注意：Dart 代码中字段名是 themeMode，但在 JSON 中是 colorMode
  static const String colorModeSystem = 'system';
  static const String colorModeLight = 'light';
  static const String colorModeDark = 'dark';
  static const String colorModeAuto = 'auto'; // 微信端可能使用，需转换为 system

  // 主题代码前缀
  static const String presetThemePrefix = 'classic-theme-';

  // 微信端使用的自定义主题占位符
  static const String wechatCustomThemePlaceholder = '自定义';
}
