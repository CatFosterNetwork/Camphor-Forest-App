import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/providers/core_providers.dart';
import 'core/services/image_cache_service.dart';
import 'core/config/providers/theme_config_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 优化高刷新率屏幕性能
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  final prefs = await SharedPreferences.getInstance();
  
  // 创建ProviderContainer用于预初始化
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  
  // 预初始化主题系统
  await _preInitializeTheme(container);
  
  await initialization();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: PlatformProvider(builder: (_) => const CamphorForestApp()),
    ),
  );
}

/// 预初始化主题系统
Future<void> _preInitializeTheme(ProviderContainer container) async {
  try {
    debugPrint('🎨 开始预初始化主题系统...');
    
    // 预加载主题列表
    await container.read(customThemesProvider.future);
    
    // 触发主题配置初始化
    container.read(themeConfigNotifierProvider);
    
    // 等待一段时间让初始化完成
    await Future.delayed(const Duration(milliseconds: 200));
    
    debugPrint('🎨 主题系统预初始化完成');
  } catch (e) {
    debugPrint('🎨 主题系统预初始化失败: $e');
    // 不阻塞应用启动，继续执行
  } finally {
    container.dispose();
  }
}

Future<void> initialization() async {
  // 初始化图片缓存服务
  final imageCacheService = ImageCacheService();
  await imageCacheService.initialize();
  
  // 预加载启动时需要的图片
  imageCacheService.preloadStartupImages();
  
  // 初始化完成后移除启动画面
  FlutterNativeSplash.remove();
}
