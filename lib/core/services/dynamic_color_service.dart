// lib/core/services/dynamic_color_service.dart

import 'dart:io';
import 'package:camphor_forest/core/models/theme_model.dart' as theme_model;
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 动态颜色服务 - 用于获取 Android 12+ 系统 Material You 颜色
class DynamicColorService {
  static final DynamicColorService _instance = DynamicColorService._internal();
  factory DynamicColorService() => _instance;
  DynamicColorService._internal();

  ColorScheme? _lightDynamicColorScheme;
  ColorScheme? _darkDynamicColorScheme;
  bool _isInitialized = false;
  bool _isSupported = false;

  /// 是否支持动态颜色（Android 12+）
  bool get isSupported => _isSupported;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化动态颜色服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 检查是否为 Android 12+
    _isSupported = await _checkDynamicColorSupport();

    if (_isSupported) {
      try {
        // 使用 dynamic_color 包获取系统颜色
        final corePalette = await DynamicColorPlugin.getCorePalette();

        if (corePalette != null) {
          _lightDynamicColorScheme = corePalette.toColorScheme();
          _darkDynamicColorScheme = corePalette.toColorScheme(
            brightness: Brightness.dark,
          );
        }
      } catch (e) {
        debugPrint('获取动态颜色失败: $e');
        _isSupported = false;
      }
    }

    _isInitialized = true;
    debugPrint('动态颜色服务初始化完成 - 支持状态: $_isSupported');
  }

  /// 检查是否支持动态颜色
  Future<bool> _checkDynamicColorSupport() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 12 对应 SDK 31
      final isAndroid12Plus = androidInfo.version.sdkInt >= 31;
      debugPrint('Android SDK 版本: ${androidInfo.version.sdkInt}');
      debugPrint('是否支持动态颜色: $isAndroid12Plus');

      return isAndroid12Plus;
    } catch (e) {
      debugPrint('检查 Android 版本失败: $e');
      return false;
    }
  }

  /// 获取浅色动态颜色方案
  ColorScheme? getLightColorScheme() {
    return _lightDynamicColorScheme;
  }

  /// 获取深色动态颜色方案
  ColorScheme? getDarkColorScheme() {
    return _darkDynamicColorScheme;
  }

  /// 获取系统主色调（用于主题）
  Color? getPrimaryColor({bool isDark = false}) {
    if (!_isSupported) return null;

    final colorScheme = isDark
        ? _darkDynamicColorScheme
        : _lightDynamicColorScheme;
    return colorScheme?.primary;
  }

  /// 获取系统颜色列表（10个渐变色，用于课表等）
  /// 如果不支持动态颜色，返回 null
  List<Color>? getDynamicColorList({bool isDark = false}) {
    if (!_isSupported) return null;

    final colorScheme = isDark
        ? _darkDynamicColorScheme
        : _lightDynamicColorScheme;
    if (colorScheme == null) return null;

    // 从系统颜色方案中提取 10 个颜色，用于课表渐变
    return [
      colorScheme.primary,
      colorScheme.primaryContainer,
      colorScheme.secondary,
      colorScheme.secondaryContainer,
      colorScheme.tertiary,
      colorScheme.tertiaryContainer,
      colorScheme.error,
      colorScheme.errorContainer,
      colorScheme.surface,
      colorScheme.surfaceContainerHighest,
    ];
  }

  /// 获取系统背景色
  Color? getBackgroundColor({bool isDark = false}) {
    if (!_isSupported) return null;

    final colorScheme = isDark
        ? _darkDynamicColorScheme
        : _lightDynamicColorScheme;
    return colorScheme?.surface;
  }

  /// 获取系统前景色（文字颜色）
  Color? getForegroundColor({bool isDark = false}) {
    if (!_isSupported) return null;

    final colorScheme = isDark
        ? _darkDynamicColorScheme
        : _lightDynamicColorScheme;
    return colorScheme?.onSurface;
  }

  /// 重新加载动态颜色（当用户更换壁纸时）
  Future<void> reload() async {
    _isInitialized = false;
    _lightDynamicColorScheme = null;
    _darkDynamicColorScheme = null;
    await initialize();
  }

  /// 创建系统动态主题（Android 12+ Material You）
  /// 如果设备不支持，返回 null
  theme_model.Theme? createSystemTheme({bool isDark = false}) {
    if (!_isSupported) return null;

    final colorList = getDynamicColorList(isDark: isDark);
    if (colorList == null || colorList.isEmpty) return null;

    return theme_model.Theme(
      title: 'Material You',
      code: 'classic-theme-system-dynamic-color',
      backColor:
          getBackgroundColor(isDark: isDark) ??
          (isDark ? Colors.black : Colors.white),
      foregColor:
          getForegroundColor(isDark: isDark) ??
          (isDark ? Colors.white : Colors.black),
      weekColor: getPrimaryColor(isDark: isDark) ?? Colors.blue,
      classTableBackgroundBlur: true,
      colorList: colorList,
      img: 'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
      indexBackgroundBlur: false,
      indexBackgroundImg:
          'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
      indexMessageBoxBlur: true,
    );
  }
}
