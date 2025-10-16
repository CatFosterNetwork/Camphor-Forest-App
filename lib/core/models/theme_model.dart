// lib/models/theme.dart

import 'package:flutter/material.dart';

class Theme {
  final String code;
  final String title;
  final String img; // 索引页背景图
  final bool indexBackgroundBlur;
  final String indexBackgroundImg; // 主界面背景图
  final bool indexMessageBoxBlur;
  final Color backColor; // 整体背景色
  final Color foregColor; // 文字/图标前景色
  final Color weekColor; // 星期文字色
  final bool classTableBackgroundBlur;
  final List<Color> colorList; // 10 段渐变色

  Theme({
    required this.code,
    required this.title,
    required this.img,
    required this.indexBackgroundBlur,
    required this.indexBackgroundImg,
    required this.indexMessageBoxBlur,
    required this.backColor,
    required this.foregColor,
    required this.weekColor,
    required this.classTableBackgroundBlur,
    required this.colorList,
  });

  /// 判断是否为预设主题
  /// 预设主题的 code 以 'classic-theme-' 开头
  bool get isPreset => code.startsWith('classic-theme-');

  /// 判断是否为自定义主题
  /// 自定义主题是非预设主题
  bool get isCustom => !isPreset;

  factory Theme.fromJson(Map<String, dynamic> json) {
    Color parseRgb(String? rgb) {
      if (rgb == null || rgb.isEmpty) {
        return const Color(0xFF5A76D0); // 默认蓝色
      }

      try {
        // 处理多种RGB格式：
        // "rgb(35, 88, 168)"
        // "rgb(255 241 242 / 1)"
        String cleanRgb = rgb
            .replaceAll('rgb(', '')
            .replaceAll('rgba(', '')
            .replaceAll(')', '')
            .replaceAll('/', '')
            .trim();

        // 使用正则表达式提取数字
        final RegExp numberRegex = RegExp(r'\d+');
        final List<String> matches = numberRegex
            .allMatches(cleanRgb)
            .map((m) => m.group(0)!)
            .toList();

        if (matches.length >= 3) {
          final int r = int.parse(matches[0]).clamp(0, 255);
          final int g = int.parse(matches[1]).clamp(0, 255);
          final int b = int.parse(matches[2]).clamp(0, 255);
          return Color.fromARGB(255, r, g, b);
        } else {
          // 如果解析失败，返回默认颜色
          return const Color(0xFF5A76D0); // 默认蓝色
        }
      } catch (e) {
        // 解析失败时返回默认颜色
        return const Color(0xFF5A76D0); // 默认蓝色
      }
    }

    return Theme(
      code: json['code'] as String? ?? 'unknown-theme',
      title: json['title'] as String? ?? '未命名主题',
      img: json['img'] as String? ?? '',
      indexBackgroundBlur: json['indexBackgroundBlur'] as bool? ?? false,
      indexBackgroundImg: json['indexBackgroundImg'] as String? ?? '',
      indexMessageBoxBlur: json['indexMessageBoxBlur'] as bool? ?? false,
      backColor: parseRgb(json['backRGB'] as String?),
      foregColor: parseRgb(json['foregRGB'] as String?),
      weekColor: parseRgb(json['weekRGB'] as String?),
      classTableBackgroundBlur:
          json['classTableBackgroundBlur'] as bool? ?? false,
      colorList:
          (json['colorList'] as List<dynamic>?)?.map((hex) {
            try {
              return Color(
                int.parse((hex as String).replaceFirst('#', '0xff')),
              );
            } catch (e) {
              return const Color(0xFF5A76D0); // 解析失败时返回默认颜色
            }
          }).toList() ??
          // 默认渐变色列表
          [
            const Color(0xFF2255A3),
            const Color(0xFF2358A8),
            const Color(0xFF275BAA),
            const Color(0xFF2C5FAB),
            const Color(0xFF3767B0),
            const Color(0xFF3969B1),
            const Color(0xFF3D6CB2),
            const Color(0xFF426FB4),
            const Color(0xFF4673B6),
            const Color(0xFF4A76B7),
          ],
    );
  }

  Map<String, dynamic> toJson() {
    String colorToRgb(Color color) {
      // 修复：使用 red、green、blue 属性（0-255整数），而不是 r、g、b（0.0-1.0浮点数）
      return 'rgb(${color.red}, ${color.green}, ${color.blue})';
    }

    String colorToHex(Color color) {
      return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    }

    return {
      'code': code,
      'title': title,
      'img': img,
      'indexBackgroundBlur': indexBackgroundBlur,
      'indexBackgroundImg': indexBackgroundImg,
      'indexMessageBoxBlur': indexMessageBoxBlur,
      'backRGB': colorToRgb(backColor),
      'foregRGB': colorToRgb(foregColor),
      'weekRGB': colorToRgb(weekColor),
      'classTableBackgroundBlur': classTableBackgroundBlur,
      'colorList': colorList.map((color) => colorToHex(color)).toList(),
    };
  }

  Theme copyWith({
    String? code,
    String? title,
    String? img,
    bool? indexBackgroundBlur,
    String? indexBackgroundImg,
    bool? indexMessageBoxBlur,
    Color? backColor,
    Color? foregColor,
    Color? weekColor,
    bool? classTableBackgroundBlur,
    List<Color>? colorList,
  }) {
    return Theme(
      code: code ?? this.code,
      title: title ?? this.title,
      img: img ?? this.img,
      indexBackgroundBlur: indexBackgroundBlur ?? this.indexBackgroundBlur,
      indexBackgroundImg: indexBackgroundImg ?? this.indexBackgroundImg,
      indexMessageBoxBlur: indexMessageBoxBlur ?? this.indexMessageBoxBlur,
      backColor: backColor ?? this.backColor,
      foregColor: foregColor ?? this.foregColor,
      weekColor: weekColor ?? this.weekColor,
      classTableBackgroundBlur:
          classTableBackgroundBlur ?? this.classTableBackgroundBlur,
      colorList: colorList ?? this.colorList,
    );
  }
}
