import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart'
    as bmf_base;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/providers/core_providers.dart';
import 'core/services/image_cache_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 优化高刷新率屏幕性能
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();

  // Android 上初始化百度地图 SDK 的隐私合规设置与坐标系
  if (defaultTargetPlatform == TargetPlatform.android) {
    // 同意隐私
    bmf_base.BMFMapSDK.setAgreePrivacy(true);
  }

  await initialization();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: PlatformProvider(builder: (_) => const CamphorForestApp()),
    ),
  );
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
