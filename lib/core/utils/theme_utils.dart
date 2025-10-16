import '../constants/theme_constants.dart';

/// 主题工具类
/// 提供统一的主题判断方法
class ThemeUtils {
  /// 判断主题代码是否为预设主题
  /// 预设主题的 code 以 'classic-theme-' 开头
  static bool isPresetTheme(String themeCode) {
    return themeCode.startsWith(ThemeConstants.presetThemePrefix);
  }

  /// 判断主题代码是否为自定义主题
  /// 自定义主题是非预设主题
  static bool isCustomTheme(String themeCode) {
    return !isPresetTheme(themeCode);
  }
}
