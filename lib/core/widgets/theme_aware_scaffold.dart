// lib/core/widgets/theme_aware_scaffold.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/providers/theme_config_provider.dart';
import '../../widgets/app_background.dart';

/// 页面类型枚举，用于不同背景策略
enum PageType {
  indexPage, // 主页
  loginPage, // 登录页
  classtable, // 课表页
  settings, // 设置页
  other, // 其他页面
}

/// 主题感知的Scaffold包装器
/// 自动应用当前选中的自定义主题
class ThemeAwareScaffold extends ConsumerWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final String? backgroundImage;
  final bool useBackground; // 是否使用背景
  final PageType pageType; // 页面类型
  final bool? resizeToAvoidBottomInset; // 是否避让键盘
  final bool addLightModeOverlay; // 是否在浅色模式下添加深色遮罩

  const ThemeAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.backgroundImage,
    this.useBackground = false, // 默认不使用背景
    this.pageType = PageType.other, // 默认其他页面
    this.resizeToAvoidBottomInset, // 可选的键盘避让设置
    this.addLightModeOverlay = false, // 默认不添加额外遮罩
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 判断是否应该使用背景
    bool shouldUseBackground;

    switch (pageType) {
      case PageType.indexPage:
      case PageType.loginPage:
      case PageType.classtable:
        shouldUseBackground = useBackground; // 使用useBackground参数直接决定
        break;
      case PageType.settings:
      case PageType.other:
        // 设置页和其他页面：深色模式时使用背景，浅色模式时不使用背景（保持纯色便于查看）
        shouldUseBackground = isDarkMode ? useBackground : false;
        break;
    }

    // 如果启用背景功能，使用AppBackground组件
    if (shouldUseBackground) {
      String imageUrl;
      bool bgBlur;

      // 根据页面类型选择不同的背景
      switch (pageType) {
        case PageType.classtable:
          imageUrl = backgroundImage ?? currentTheme.img;
          bgBlur = currentTheme.classTableBackgroundBlur;
          break;
        case PageType.indexPage:
        case PageType.loginPage:
        case PageType.settings:
        case PageType.other:
          imageUrl = backgroundImage ?? currentTheme.indexBackgroundImg;
          bgBlur = currentTheme.indexBackgroundBlur;
          break;
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar as PreferredSizeWidget?,
        extendBodyBehindAppBar: true, // 让AppBar透明时内容延伸到AppBar下方
        resizeToAvoidBottomInset:
            resizeToAvoidBottomInset ?? false, // 默认固定背景，除非明确指定
        body: Stack(
          children: [
            // 使用统一的AppBackground组件
            Positioned.fill(
              child: AppBackground(
                imageUrl: imageUrl,
                blur: bgBlur,
                overlay: true,
                overlayColor: isDarkMode ? Colors.black54 : Colors.white24,
                isDarkMode: isDarkMode,
                addLightModeOverlay: addLightModeOverlay,
              ),
            ),
            // 页面内容，加上安全区域
            SafeArea(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    // 不使用背景时的普通Scaffold
    Color scaffoldBackgroundColor;
    if (isDarkMode) {
      scaffoldBackgroundColor = const Color(0xFF202125);
    } else {
      // 浅色模式下根据页面类型选择不同的背景色
      switch (pageType) {
        case PageType.settings:
        case PageType.other:
        case PageType.indexPage:
        case PageType.loginPage:
          // 设置页面使用固定的淡灰色，与卡片颜色有区别
          scaffoldBackgroundColor = Colors.grey.shade50; // 淡灰色背景
          break;
        case PageType.classtable:
          // 其他页面使用主题色或默认浅灰色
          scaffoldBackgroundColor = currentTheme.backColor;
          break;
      }
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: appBar as PreferredSizeWidget?,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset, // 无背景页面可能需要键盘避让
    );
  }
}

/// 主题感知的应用栏
class ThemeAwareAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool transparent; // 新增：是否透明

  const ThemeAwareAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.transparent = true, // 默认透明
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    // 确定背景颜色
    final Color bgColor;
    if (transparent) {
      // 如果设置为透明，使用完全透明的背景
      bgColor = Colors.transparent;
    } else if (backgroundColor != null) {
      // 如果传入了自定义背景色，使用自定义背景色
      bgColor = backgroundColor!;
    } else {
      // 默认背景色
      bgColor = isDarkMode ? const Color(0xFF202125) : Colors.grey.shade50;
    }

    // 确定前景颜色 - 确保在浅色模式下有足够对比度
    final Color fgColor;
    if (foregroundColor != null) {
      fgColor = foregroundColor!;
    } else if (isDarkMode) {
      // 深色模式：使用白色文字
      fgColor = Colors.white;
    } else {
      // 浅色模式：使用深色文字，确保与淡灰色背景有对比度
      fgColor = Colors.black;
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: transparent ? Colors.transparent : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 简单的透明AppBar组件
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color textColor;

  const TransparentAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
