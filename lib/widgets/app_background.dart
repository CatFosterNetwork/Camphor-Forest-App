import 'dart:ui';

import 'package:flutter/material.dart';
import 'fade_background.dart';

/// 通用背景组件，支持：
/// 1. 图片渐变切换（使用 [FadeBackground]）
/// 2. 可选半透明遮罩层
/// 3. 可选高斯模糊
/// 4. 深色模式适配
/// 5. 可选额外深色遮罩（用于登录页文字对比度）
///
/// 适用于登录页、首页等需要背景图的场景。
class AppBackground extends StatelessWidget {
  /// 背景图片地址，为空则使用主题背景色
  final String? imageUrl;

  /// 是否叠加模糊效果
  final bool blur;

  /// 是否叠加半透明遮罩
  final bool overlay;

  /// 遮罩颜色，只有 [overlay] 为 true 时生效
  final Color overlayColor;

  /// 是否为深色模式，深色模式下使用纯色背景
  final bool? isDarkMode;

  /// 是否在浅色模式下添加额外的深色遮罩（用于提高文字对比度）
  final bool addLightModeOverlay;

  const AppBackground({
    super.key,
    this.imageUrl,
    this.blur = false,
    this.overlay = false,
    this.overlayColor = const Color(0x33000000),
    this.isDarkMode,
    this.addLightModeOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> layers = [];
    
    // 确定是否为深色模式
    final effectiveIsDarkMode = isDarkMode ?? 
        (Theme.of(context).brightness == Brightness.dark);

    // 深色模式下使用纯色背景
    if (effectiveIsDarkMode) {
      debugPrint('AppBackground: 深色模式激活，使用纯色背景 #202125');
      layers.add(Container(color: const Color(0xFF202125)));
    } else {
      debugPrint('AppBackground: 浅色模式，显示背景图片: $imageUrl');
      // 浅色模式下正常显示背景图片
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        // 确保URL以http开头，否则使用默认背景
        if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
          debugPrint('AppBackground: 使用网络图片: $imageUrl');
          layers.add(FadeBackground(imageUrl!));
        } else {
          debugPrint('AppBackground: 无效的URL格式，使用默认背景: $imageUrl');
          layers.add(Container(color: Theme.of(context).colorScheme.surface));
        }
      } else {
        layers.add(Container(color: Theme.of(context).colorScheme.surface));
      }
      
      // 遮罩层（仅浅色模式）
      if (overlay) {
        layers.add(Container(color: overlayColor));
      }
      
      // 为登录页面在浅色模式下添加额外的深色遮罩以提高对比度
      // 这样可以确保遮罩覆盖整个屏幕，包括状态栏区域
      if (addLightModeOverlay && !effectiveIsDarkMode) {
        layers.add(Container(color: const Color(0x66000000))); // 40% 透明度的黑色遮罩
      }

      // 模糊层（仅浅色模式） - 使用真正的BackdropFilter
      if (blur) {
        layers.add(
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
                color: Colors.white.withAlpha(128), // 增加背景对比度
            ),
          ),
        );
      }
    }

    // 使用Container包装确保背景始终填满整个区域，包括可能的overscroll区域
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand, 
        children: layers,
      ),
    );
  }
}
