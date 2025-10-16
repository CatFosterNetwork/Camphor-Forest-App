// lib/core/utils/theme_aware_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/providers/theme_config_provider.dart';

/// 主题感知对话框工具类
///
/// 根据当前平台和主题类型自动选择合适的对话框样式：
/// - iOS：全部使用 FlutterPlatformAlert（原生对话框）
/// - Android 系统动态主题（Material You）：使用 FlutterPlatformAlert（原生系统对话框）
/// - Android 其他主题：使用自定义对话框（应用软件主题色）
class ThemeAwareDialog {
  /// 系统动态主题的 code 标识
  static const String _systemThemeCode = 'classic-theme-system-dynamic-color';

  /// 从 BuildContext 获取当前主题的 code
  static String? _getThemeCode(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      final themeCode = container.read(selectedThemeCodeProvider);
      return themeCode;
    } catch (e) {
      debugPrint('ThemeAwareDialog: 无法获取主题 code: $e');
      return null;
    }
  }

  /// 从 BuildContext 获取当前主题色
  static Color _getThemeColor(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      final currentTheme = container.read(selectedCustomThemeProvider);
      if (currentTheme.colorList.isNotEmpty) {
        return currentTheme.colorList[0];
      }
    } catch (e) {
      debugPrint('ThemeAwareDialog: 无法获取主题色: $e');
    }
    return Colors.blue;
  }

  /// 从 BuildContext 获取暗黑模式状态
  static bool _getIsDarkMode(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context);
      return container.read(effectiveIsDarkModeProvider);
    } catch (e) {
      debugPrint('ThemeAwareDialog: 无法获取暗黑模式状态: $e');
      return false;
    }
  }

  /// 判断是否应该使用原生对话框
  /// iOS: 总是使用原生对话框
  /// Android: 只有选择系统主题时使用原生对话框
  static bool _shouldUseNativeDialog(BuildContext context) {
    if (Platform.isIOS) {
      return true; // iOS 全部使用原生对话框
    }
    // Android: 只有系统主题使用原生对话框
    final themeCode = _getThemeCode(context);
    return themeCode == _systemThemeCode;
  }

  /// 根据背景色判断应该使用浅色还是深色文字
  static Color _getTextColor(Color backgroundColor) {
    // 计算亮度：使用 YIQ 公式
    final brightness =
        (backgroundColor.red * 299 +
            backgroundColor.green * 587 +
            backgroundColor.blue * 114) /
        1000;
    // 亮度 > 128 使用深色文字，否则使用浅色文字
    return brightness > 128 ? Colors.black : Colors.white;
  }

  /// 显示确认对话框
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String positiveText = '确定',
    String negativeText = '取消',
  }) async {
    // 判断是否使用原生对话框（内部自动获取 themeCode）
    if (_shouldUseNativeDialog(context)) {
      final result = await FlutterPlatformAlert.showCustomAlert(
        windowTitle: title,
        text: message,
        positiveButtonTitle: positiveText,
        negativeButtonTitle: negativeText,
      );
      return result == CustomButton.positiveButton;
    }

    // 使用自定义对话框（应用软件主题色）
    final themeColor = _getThemeColor(context);
    final isDarkMode = _getIsDarkMode(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildCustomConfirmDialog(
        context,
        title: title,
        message: message,
        themeColor: themeColor,
        isDarkMode: isDarkMode,
        positiveText: positiveText,
        negativeText: negativeText,
      ),
    );

    return result ?? false;
  }

  /// 显示提示对话框（只有确定按钮）
  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = '确定',
  }) async {
    // 判断是否使用原生对话框（内部自动获取 themeCode）
    if (_shouldUseNativeDialog(context)) {
      await FlutterPlatformAlert.showAlert(
        windowTitle: title,
        text: message,
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
      return;
    }

    // 使用自定义对话框
    final themeColor = _getThemeColor(context);
    final isDarkMode = _getIsDarkMode(context);

    await showDialog(
      context: context,
      builder: (context) => _buildCustomAlertDialog(
        context,
        title: title,
        message: message,
        themeColor: themeColor,
        isDarkMode: isDarkMode,
        buttonText: buttonText,
      ),
    );
  }

  /// 构建自定义确认对话框
  static Widget _buildCustomConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color themeColor,
    required bool isDarkMode,
    required String positiveText,
    required String negativeText,
  }) {
    final textColor = _getTextColor(themeColor);
    final contentTextColor = textColor.withOpacity(0.87);

    return AlertDialog(
      backgroundColor: themeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(color: contentTextColor, fontSize: 16),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            negativeText,
            style: TextStyle(
              color: contentTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            positiveText,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建自定义提示对话框
  static Widget _buildCustomAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Color themeColor,
    required bool isDarkMode,
    required String buttonText,
  }) {
    final textColor = _getTextColor(themeColor);
    final contentTextColor = textColor.withOpacity(0.87);

    return AlertDialog(
      backgroundColor: themeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(color: contentTextColor, fontSize: 16),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
