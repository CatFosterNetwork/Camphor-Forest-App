// lib/core/utils/json_compatibility_validator.dart
// 验证主题系统与用户提供的JSON格式完全兼容

import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import '../models/theme_model.dart' as theme_model;

class JsonCompatibilityValidator {
  /// 验证所有用户提供的主题JSON格式
  static Future<bool> validateAllThemes() async {
    AppLogger.debug('🧪 开始验证主题JSON兼容性...\n');

    bool allPassed = true;

    // 测试默认主题
    allPassed &= await _validateTheme(_getDefaultThemeJson(), '默认主题');

    // 测试森林主题
    allPassed &= await _validateTheme(_getForestThemeJson(), '森林主题');

    // 测试海洋主题
    allPassed &= await _validateTheme(_getOceanThemeJson(), '海洋主题');

    // 测试往返转换
    allPassed &= await _validateRoundTripConversion();

    AppLogger.debug(allPassed ? '✅ 所有主题JSON验证通过！' : '❌ 部分主题JSON验证失败！');
    return allPassed;
  }

  /// 验证单个主题
  static Future<bool> _validateTheme(
    Map<String, dynamic> themeJson,
    String themeName,
  ) async {
    try {
      // 测试 fromJson
      final theme = theme_model.Theme.fromJson(themeJson);

      // 验证基本属性
      assert(theme.code == themeJson['code']);
      assert(theme.title == themeJson['title']);
      assert(theme.img == themeJson['img']);
      assert(theme.indexBackgroundBlur == themeJson['indexBackgroundBlur']);
      assert(theme.indexBackgroundImg == themeJson['indexBackgroundImg']);
      assert(theme.indexMessageBoxBlur == themeJson['indexMessageBoxBlur']);
      assert(
        theme.classTableBackgroundBlur == themeJson['classTableBackgroundBlur'],
      );

      // 验证颜色解析
      final colorList = themeJson['colorList'] as List<dynamic>;
      assert(theme.colorList.length == colorList.length);

      // 测试 toJson
      final outputJson = theme.toJson();

      // 验证输出格式
      assert(outputJson.containsKey('backRGB'));
      assert(outputJson.containsKey('foregRGB'));
      assert(outputJson.containsKey('weekRGB'));
      assert(outputJson.containsKey('colorList'));

      // 验证RGB格式
      final backRGB = outputJson['backRGB'] as String;
      assert(backRGB.startsWith('rgb(') && backRGB.endsWith(')'));

      AppLogger.debug('✅ $themeName 验证通过');
      AppLogger.debug('  - 代码: ${theme.code}');
      AppLogger.debug('  - 颜色数量: ${theme.colorList.length}');
      AppLogger.debug('  - RGB输出: ${outputJson['backRGB']}');

      return true;
    } catch (e, stackTrace) {
      AppLogger.debug('❌ $themeName 验证失败: $e');
      AppLogger.debug('堆栈: $stackTrace');
      return false;
    }
  }

  /// 验证往返转换一致性
  static Future<bool> _validateRoundTripConversion() async {
    try {
      final originalJson = _getDefaultThemeJson();

      // JSON -> Theme -> JSON
      final theme = theme_model.Theme.fromJson(originalJson);
      final outputJson = theme.toJson();

      // JSON -> Theme -> JSON -> Theme
      final themeRoundTrip = theme_model.Theme.fromJson(outputJson);

      // 验证一致性
      assert(theme.code == themeRoundTrip.code);
      assert(theme.title == themeRoundTrip.title);
      assert(theme.backColor.toARGB32() == themeRoundTrip.backColor.toARGB32());
      assert(
        theme.foregColor.toARGB32() == themeRoundTrip.foregColor.toARGB32(),
      );
      assert(theme.weekColor.toARGB32() == themeRoundTrip.weekColor.toARGB32());
      assert(theme.colorList.length == themeRoundTrip.colorList.length);

      AppLogger.debug('✅ 往返转换一致性验证通过');
      return true;
    } catch (e) {
      AppLogger.debug('❌ 往返转换一致性验证失败: $e');
      return false;
    }
  }

  /// 获取默认主题JSON（用户提供格式）
  static Map<String, dynamic> _getDefaultThemeJson() {
    return {
      "code": "default",
      "title": "默认主题",
      "img": "splash_background.png",
      "indexBackgroundBlur": true,
      "indexBackgroundImg": "splash_background.png",
      "indexMessageBoxBlur": true,
      "backRGB": "rgb(245, 245, 247)",
      "foregRGB": "rgb(51, 51, 51)",
      "weekRGB": "rgb(102, 102, 102)",
      "classTableBackgroundBlur": true,
      "colorList": [
        "#FF6B6B",
        "#4ECDC4",
        "#45B7D1",
        "#96CEB4",
        "#FECA57",
        "#FF9FF3",
        "#54A0FF",
        "#5F27CD",
        "#00D2D3",
        "#FF9F43",
      ],
    };
  }

  /// 获取森林主题JSON
  static Map<String, dynamic> _getForestThemeJson() {
    return {
      "code": "forest",
      "title": "森林主题",
      "img": "splash_background.png",
      "indexBackgroundBlur": true,
      "indexBackgroundImg": "splash_background.png",
      "indexMessageBoxBlur": true,
      "backRGB": "rgb(240, 248, 255)",
      "foregRGB": "rgb(47, 79, 79)",
      "weekRGB": "rgb(85, 107, 47)",
      "classTableBackgroundBlur": true,
      "colorList": [
        "#228B22",
        "#32CD32",
        "#90EE90",
        "#98FB98",
        "#00FF7F",
        "#7CFC00",
        "#ADFF2F",
        "#9AFF9A",
        "#00FA9A",
        "#3CB371",
      ],
    };
  }

  /// 获取海洋主题JSON
  static Map<String, dynamic> _getOceanThemeJson() {
    return {
      "code": "ocean",
      "title": "海洋主题",
      "img": "splash_background.png",
      "indexBackgroundBlur": true,
      "indexBackgroundImg": "splash_background.png",
      "indexMessageBoxBlur": true,
      "backRGB": "rgb(240, 248, 255)",
      "foregRGB": "rgb(25, 25, 112)",
      "weekRGB": "rgb(70, 130, 180)",
      "classTableBackgroundBlur": true,
      "colorList": [
        "#1E90FF",
        "#87CEEB",
        "#4682B4",
        "#5F9EA0",
        "#6495ED",
        "#7B68EE",
        "#9370DB",
        "#8A2BE2",
        "#4169E1",
        "#0000FF",
      ],
    };
  }

  /// 验证RGB颜色解析
  static bool validateRgbParsing(String rgbString, Color expectedColor) {
    try {
      final nums = rgbString
          .replaceAll(RegExp(r'[^\d,]'), '')
          .split(',')
          .map(int.parse)
          .toList();
      final parsedColor = Color.fromARGB(255, nums[0], nums[1], nums[2]);
      return parsedColor.toARGB32() == expectedColor.toARGB32();
    } catch (e) {
      return false;
    }
  }

  /// 验证十六进制颜色解析
  static bool validateHexParsing(String hexString, Color expectedColor) {
    try {
      final parsedColor = Color(int.parse(hexString.replaceFirst('#', '0xff')));
      return parsedColor.toARGB32() == expectedColor.toARGB32();
    } catch (e) {
      return false;
    }
  }
}
