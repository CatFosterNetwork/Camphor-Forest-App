// lib/app.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/providers/theme_config_provider.dart';
import 'core/navigation/app_router.dart';
import 'core/services/navigation_service.dart';

import 'core/models/theme_model.dart' as theme_model;

class CamphorForestApp extends ConsumerWidget {
  const CamphorForestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 使用统一的状态栏服务管理状态栏样式
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      debugPrint('🏠[$timestamp] App级别主题信息:');
      debugPrint('  - themeMode: $themeMode');
      debugPrint('  - isDarkMode: $isDarkMode');
      debugPrint('  - currentTheme: ${currentTheme.title}');
      debugPrint('  - currentTheme.code: ${currentTheme.code}');
      debugPrint(
        '  - MaterialApp.themeMode: ${_convertStringToThemeMode(themeMode)}',
      );

      // 状态栏现在由AdaptiveStatusBar声明式管理，无需手动设置
    });

    // 平台判断
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIos) {
      return CupertinoApp.router(
        routerConfig: router,
        title: '樟木林Toolbox',
        theme: _buildCupertinoTheme(currentTheme, isDarkMode),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      );
    } else {
      return MaterialApp.router(
        routerConfig: router,
        title: '樟木林Toolbox',
        scaffoldMessengerKey: NavigationService.messengerKey,
        themeMode: _convertStringToThemeMode(themeMode),
        theme: _buildLightTheme(currentTheme),
        darkTheme: _buildDarkTheme(currentTheme),
        debugShowCheckedModeBanner: false,
        // 优化高刷新率屏幕性能和状态栏管理
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // 确保高刷新率设备能正确识别
              devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
            ),
            child: child!,
          );
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      );
    }
  }

  /// 将字符串主题模式转换为ThemeMode枚举
  ThemeMode _convertStringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// 构建浅色主题
  ThemeData _buildLightTheme(theme_model.Theme? customTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // 使用自定义主题的颜色配置
      colorScheme: ColorScheme.fromSeed(
        seedColor: customTheme?.colorList.first ?? Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: customTheme?.backColor ?? Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 构建深色主题
  ThemeData _buildDarkTheme(theme_model.Theme? customTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: customTheme?.colorList.first ?? Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF202125),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey.shade800,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 构建Cupertino主题
  CupertinoThemeData _buildCupertinoTheme(
    theme_model.Theme? customTheme,
    bool isDarkMode,
  ) {
    return CupertinoThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: customTheme?.colorList.first ?? CupertinoColors.systemBlue,
      scaffoldBackgroundColor: isDarkMode
          ? const Color(0xFF202125)
          : (customTheme?.backColor ?? CupertinoColors.systemBackground),
    );
  }
}
