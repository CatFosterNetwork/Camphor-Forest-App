// lib/core/widgets/adaptive_status_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/providers/theme_config_provider.dart';
import 'theme_aware_scaffold.dart';

/// 自适应状态栏组件 - 重构版
/// 采用声明式AnnotatedRegion方法，自动根据主题模式设置状态栏样式
class AdaptiveStatusBar extends ConsumerWidget {
  final Widget child;
  final PageType pageType;
  final bool hasBackground;
  final Brightness? forceIconBrightness;
  final Color? backgroundColor;

  const AdaptiveStatusBar({
    super.key,
    required this.child,
    required this.pageType,
    this.hasBackground = false,
    this.forceIconBrightness,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final statusBarStyle = _getStatusBarStyle(isDarkMode);

    // 添加调试信息
    debugPrint('📱 StatusBar [${pageType.name}] 构建状态栏配置:');
    debugPrint('   🌓 isDarkMode: $isDarkMode');
    debugPrint('   🎨 hasBackground: $hasBackground');
    debugPrint('   🔧 forceIconBrightness: $forceIconBrightness');
    debugPrint('   🎯 backgroundColor: $backgroundColor');
    debugPrint('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: child,
    );
  }
  
  /// 获取状态栏样式 - 修正了iOS和Android的亮度逻辑
  SystemUiOverlayStyle _getStatusBarStyle(bool isDarkMode) {
    debugPrint('   🔍 开始计算状态栏样式...');
    
    // 确定状态栏背景颜色
    final Color statusBarColor;
    if (hasBackground) {
      statusBarColor = Colors.transparent;
      debugPrint('   🎨 状态栏背景: 透明 (hasBackground=true)');
    } else {
      statusBarColor = backgroundColor ?? 
        (isDarkMode ? const Color(0xFF202125) : Colors.white);
      if (backgroundColor != null) {
        debugPrint('   🎨 状态栏背景: 自定义颜色 $backgroundColor');
      } else {
        debugPrint('   🎨 状态栏背景: ${isDarkMode ? "深色主题 (0xFF202125)" : "浅色主题 (白色)"}');
      }
    }
    
    // 确定图标亮度 - 优先使用强制指定的亮度
    final Brightness iconBrightness;
    if (forceIconBrightness != null) {
      iconBrightness = forceIconBrightness!;
      debugPrint('   💡 图标亮度: 强制指定 -> ${iconBrightness.name}');
    } else {
      // 根据主题模式自动判断
      iconBrightness = isDarkMode ? Brightness.light : Brightness.dark;
      debugPrint('   💡 图标亮度: 自动判断 -> ${iconBrightness.name} (基于 isDarkMode=$isDarkMode)');
    }
    
    // iOS的statusBarBrightness逻辑与Android相反
    final Brightness iosStatusBarBrightness = iconBrightness == Brightness.light 
        ? Brightness.dark   // 浅色图标 -> iOS需要dark背景
        : Brightness.light; // 深色图标 -> iOS需要light背景
    
    debugPrint('   🤖 Android statusBarIconBrightness: ${iconBrightness.name}');
    debugPrint('   🍎 iOS statusBarBrightness: ${iosStatusBarBrightness.name} (逻辑相反)');
    
    final navigationBarColor = isDarkMode 
        ? const Color(0xFF202125) 
        : Colors.white;
    final navigationBarIconBrightness = isDarkMode 
        ? Brightness.light 
        : Brightness.dark;
    
    debugPrint('   🧭 导航栏颜色: ${isDarkMode ? "深色 (0xFF202125)" : "浅色 (白色)"}');
    debugPrint('   🧭 导航栏图标: ${navigationBarIconBrightness.name}');
    debugPrint('   ✅ 状态栏配置完成！');
    debugPrint('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return SystemUiOverlayStyle(
      // 状态栏背景色
      statusBarColor: statusBarColor,
      
      // Android 图标亮度
      statusBarIconBrightness: iconBrightness,
      
      // iOS 状态栏亮度（逻辑相反）
      statusBarBrightness: iosStatusBarBrightness,
      
      // 导航栏样式
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarIconBrightness: navigationBarIconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }
}