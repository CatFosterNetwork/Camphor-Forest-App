// lib/core/config/providers/theme_config_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../models/theme_config.dart';
import '../services/theme_config_service.dart';
import '../../models/theme_model.dart' as theme_model;
import '../../services/custom_theme_service.dart';
import '../../services/dynamic_color_service.dart';

/// 主题配置服务提供者
final themeConfigServiceProvider = Provider<ThemeConfigService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // 从core_providers获取customThemeService
  final customThemeService = ref.watch(customThemeServiceProvider);
  return ThemeConfigService(prefs, customThemeService);
});

/// 主题配置提供者（异步加载）
final themeConfigAsyncProvider = FutureProvider<ThemeConfig>((ref) async {
  final service = ref.watch(themeConfigServiceProvider);
  return await service.loadConfig();
});

/// 主题配置状态管理器
class ThemeConfigNotifier extends StateNotifier<AsyncValue<ThemeConfig>> {
  final ThemeConfigService _service;
  bool _isInitialized = false;

  ThemeConfigNotifier(this._service) : super(const AsyncValue.loading()) {
    _initializeThemeSystem();
  }

  /// 初始化主题系统
  Future<void> _initializeThemeSystem() async {
    if (_isInitialized) {
      AppLogger.debug('ThemeConfigNotifier: 已经初始化过，跳过重复初始化');
      return;
    }

    try {
      _isInitialized = true;
      state = const AsyncValue.loading();
      final config = await _service.loadConfig();

      // 如果配置中没有主题对象，尝试加载
      if (config.selectedTheme == null &&
          config.selectedThemeCode != 'custom') {
        await _ensureThemeObjectLoaded(config);
      }

      state = AsyncValue.data(config);
      AppLogger.debug(
        'ThemeConfigNotifier: 主题系统初始化成功，当前主题: ${config.selectedThemeCode}, 主题模式: ${config.themeMode}',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('ThemeConfigNotifier: 主题系统初始化失败: $e');
    }
  }

  /// 确保主题对象已加载
  Future<void> _ensureThemeObjectLoaded(ThemeConfig config) async {
    try {
      // 等待CustomThemeManager加载主题列表
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // 给CustomThemeManager一点时间初始化

      // 这里暂时先使用默认主题对象，等主题列表加载完成后会自动更新
      AppLogger.debug('ThemeConfigNotifier: 等待主题列表加载完成后自动同步主题对象');
    } catch (e) {
      AppLogger.debug('ThemeConfigNotifier: 加载主题对象失败: $e');
    }
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    await _initializeThemeSystem();
  }

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    try {
      AppLogger.debug('ThemeConfigNotifier: 准备设置主题模式为 $mode');
      final updatedConfig = await _service.setThemeMode(mode);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('ThemeConfigNotifier: 主题模式已设置为 $mode');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.debug('ThemeConfigNotifier: 设置主题模式失败: $e');
    }
  }

  /// 设置深色模式
  Future<void> setDarkMode(bool isDark) async {
    try {
      final updatedConfig = await _service.setDarkMode(isDark);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('ThemeConfigNotifier: 深色模式设置为 $isDark');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 选择主题
  Future<void> selectTheme(String themeCode, theme_model.Theme? theme) async {
    try {
      final updatedConfig = await _service.selectTheme(themeCode, theme);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('ThemeConfigNotifier: 选择主题 $themeCode');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 设置自定义主题
  Future<void> setCustomTheme(theme_model.Theme customTheme) async {
    try {
      final updatedConfig = await _service.setCustomTheme(customTheme);
      state = AsyncValue.data(updatedConfig);
      AppLogger.debug('ThemeConfigNotifier: 设置自定义主题');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 切换深色/浅色模式
  Future<void> toggleDarkMode() async {
    try {
      final updatedConfig = await _service.toggleDarkMode();
      state = AsyncValue.data(updatedConfig);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 循环切换主题模式
  Future<void> cycleThemeMode() async {
    try {
      final updatedConfig = await _service.cycleThemeMode();
      state = AsyncValue.data(updatedConfig);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    try {
      final defaultConfig = await _service.resetToDefault();
      state = AsyncValue.data(defaultConfig);
      AppLogger.debug('ThemeConfigNotifier: 重置为默认配置');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 重新加载配置
  Future<void> reload() async {
    AppLogger.debug('ThemeConfigNotifier: 手动重新加载配置');
    _isInitialized = false; // 允许重新初始化
    await _loadConfig();
  }

  /// 获取当前配置（同步）
  ThemeConfig? get currentConfig {
    return state.whenOrNull(data: (config) => config);
  }
}

/// 主题配置状态管理提供者
final themeConfigNotifierProvider =
    StateNotifierProvider<ThemeConfigNotifier, AsyncValue<ThemeConfig>>((ref) {
      final service = ref.watch(themeConfigServiceProvider);
      return ThemeConfigNotifier(service);
    });

// ===== 派生状态提供者 =====

/// 主题模式提供者
final themeModeProvider = Provider<String>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.themeMode,
    loading: () => 'system',
    error: (_, _) => 'system',
  );
});

/// 深色模式设置提供者
final darkModeSettingProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.isDarkMode,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// 系统亮度监听提供者
final systemBrightnessProvider = StreamProvider<Brightness>((ref) {
  late StreamController<Brightness> controller;

  void onPlatformBrightnessChanged() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (!controller.isClosed) {
      controller.add(brightness);
    }
  }

  controller = StreamController<Brightness>(
    onListen: () {
      // 添加初始值
      controller.add(
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
      );
      // 监听系统亮度变化
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
          onPlatformBrightnessChanged;
    },
    onCancel: () {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
          null;
      controller.close();
    },
  );

  ref.onDispose(() {
    if (!controller.isClosed) {
      controller.close();
    }
  });

  return controller.stream.distinct();
});

/// 有效深色模式提供者（考虑system模式和系统亮度变化）
final effectiveDarkModeProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  final systemBrightness = ref.watch(systemBrightnessProvider);

  final result = configAsync.when(
    data: (config) {
      if (config.themeMode == 'system') {
        // 如果是system模式，直接使用系统亮度
        final isDark = systemBrightness.when(
          data: (brightness) {
            final isDark = brightness == Brightness.dark;
            AppLogger.debug(
              '🌓 主题模式变化: System模式 -> 系统亮度=${brightness.name} -> isDark=$isDark',
            );
            return isDark;
          },
          loading: () {
            final isDark =
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
            AppLogger.debug('🌓 主题模式变化: System模式 (加载中) -> isDark=$isDark');
            return isDark;
          },
          error: (_, _) {
            AppLogger.debug('🌓 主题模式变化: System模式 (错误) -> 默认浅色模式');
            return false;
          },
        );
        return isDark;
      }
      final isDark = config.getEffectiveDarkMode();
      AppLogger.debug('🌓 主题模式变化: 手动模式(${config.themeMode}) -> isDark=$isDark');
      return isDark;
    },
    loading: () {
      AppLogger.debug('🌓 主题模式变化: 配置加载中 -> 默认浅色模式');
      return false;
    },
    error: (_, _) {
      AppLogger.debug('🌓 主题模式变化: 配置错误 -> 默认浅色模式');
      return false;
    },
  );

  return result;
});

/// 当前主题提供者（结合配置和主题列表）
/// 现在总是返回一个有效的主题对象，不会返回null
final currentThemeProvider = Provider<theme_model.Theme>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  final themesAsync = ref.watch(customThemesProvider);

  return configAsync.when(
    data: (config) {
      // 如果使用预设主题，直接使用 selectedTheme
      if (config.selectedTheme != null && !config.isUsingCustomTheme) {
        return config.selectedTheme!;
      }

      // 如果使用自定义主题，从主题列表中查找
      return themesAsync.when(
        data: (themes) {
          final foundTheme = themes.where(
            (theme) => theme.code == config.selectedThemeCode,
          );
          if (foundTheme.isNotEmpty) {
            return foundTheme.first;
          }

          // 如果找不到指定主题，返回默认的"你好西大人"主题
          AppLogger.debug('⚠️ 找不到主题 ${config.selectedThemeCode}，使用默认主题');
          return _createDefaultTheme();
        },
        loading: () {
          // 主题列表加载中时，返回默认主题避免null
          AppLogger.debug('⚠️ 主题列表加载中，使用默认主题');
          return _createDefaultTheme();
        },
        error: (error, _) {
          // 主题列表加载失败时，返回默认主题避免null
          AppLogger.debug('⚠️ 主题列表加载失败: $error，使用默认主题');
          return _createDefaultTheme();
        },
      );
    },
    loading: () {
      // 配置加载中时，返回默认主题避免null
      AppLogger.debug('⚠️ 主题配置加载中，使用默认主题');
      return _createDefaultTheme();
    },
    error: (error, _) {
      // 配置加载失败时，返回默认主题避免null
      AppLogger.debug('⚠️ 主题配置加载失败: $error，使用默认主题');
      return _createDefaultTheme();
    },
  );
});

/// 选中的主题代码提供者
final selectedThemeCodeProvider = selectedThemeCodeNotifierProvider;

/// 是否使用自定义主题提供者
final isUsingCustomThemeProvider = Provider<bool>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  return configAsync.when(
    data: (config) => config.isUsingCustomTheme,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// 自定义主题列表提供者（从 CustomThemeService 单一数据源获取）
final customThemesListProvider = FutureProvider<List<theme_model.Theme>>((
  ref,
) async {
  final service = ref.watch(customThemeServiceProvider);
  return service.getCustomThemes();
});

/// 所有可用主题提供者
final availableThemesProvider = FutureProvider<List<theme_model.Theme>>((
  ref,
) async {
  final service = ref.watch(themeConfigServiceProvider);
  return await service.getAllThemes();
});

// ===== 便利提供者 =====

/// 主题模式显示名称提供者
final themeModeDisplayNameProvider = Provider<String>((ref) {
  final mode = ref.watch(themeModeProvider);
  switch (mode) {
    case 'system':
      return '跟随系统';
    case 'light':
      return '浅色';
    case 'dark':
      return '深色';
    default:
      return '跟随系统';
  }
});

/// 主题切换选项提供者
final themeModeOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'value': 'system', 'label': '跟随系统'},
    {'value': 'light', 'label': '浅色'},
    {'value': 'dark', 'label': '深色'},
  ];
});

/// 当前主题信息提供者（用于UI显示）
final currentThemeInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final configAsync = ref.watch(themeConfigNotifierProvider);
  return configAsync.when(
    data: (config) => {
      'mode': config.themeMode,
      'isDark': config.getEffectiveDarkMode(),
      'themeCode': config.selectedThemeCode,
      'isCustom': config.isUsingCustomTheme,
    },
    loading: () => {
      'mode': 'system',
      'isDark': false,
      'themeCode': 'classic-theme-1', // 默认为你好西大人主题
      'isCustom': false,
    },
    error: (_, _) => {
      'mode': 'system',
      'isDark': false,
      'themeCode': 'classic-theme-1', // 默认为你好西大人主题
      'isCustom': false,
    },
  );
});

// ===== 兼容性提供者（用于替换旧系统） =====

/// 兼容旧的selectedCustomThemeProvider
final selectedCustomThemeProvider = currentThemeProvider;

/// 创建默认主题的全局函数
theme_model.Theme _createDefaultTheme() {
  // 你好西大人主题的标准配置（与themes.json保持一致）
  return theme_model.Theme(
    code: 'classic-theme-1',
    title: '你好西大人',
    img:
        'https://data.swu.social/service/external_files/2301371392301561862291631292311861844564564.webp',
    indexBackgroundBlur: false,
    indexBackgroundImg: 'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
    indexMessageBoxBlur: true,
    backColor: const Color.fromRGBO(35, 88, 168, 1), // 确保使用正确的RGB值
    foregColor: const Color.fromRGBO(255, 255, 255, 1),
    weekColor: const Color.fromRGBO(221, 221, 221, 1),
    classTableBackgroundBlur: false,
    colorList: const [
      Color(0xFF2255a3),
      Color(0xFF2358a8),
      Color(0xFF275baa),
      Color(0xFF2c5fab),
      Color(0xFF3767b0),
      Color(0xFF3969b1),
      Color(0xFF3d6cb2),
      Color(0xFF426fb4),
      Color(0xFF4673b6),
      Color(0xFF4a76b7),
    ],
  );
}

/// 兼容旧的effectiveIsDarkModeProvider
final effectiveIsDarkModeProvider = effectiveDarkModeProvider;

// ===== 自定义主题管理提供者（从旧系统迁移） =====

/// 自定义主题服务提供者
final customThemeServiceProvider = Provider<CustomThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomThemeService(prefs);
});

/// 自定义主题管理器提供者
final customThemeManagerProvider =
    StateNotifierProvider<
      CustomThemeManager,
      AsyncValue<List<theme_model.Theme>>
    >((ref) {
      final service = ref.watch(customThemeServiceProvider);
      return CustomThemeManager(service);
    });

/// 所有自定义主题提供者（包括预设和用户自定义）
final customThemesProvider = FutureProvider<List<theme_model.Theme>>((
  ref,
) async {
  final manager = ref.watch(customThemeManagerProvider);
  return manager.when(
    data: (themes) => themes,
    loading: () => <theme_model.Theme>[],
    error: (_, _) => <theme_model.Theme>[],
  );
});

/// 选中主题代码的状态管理器
class SelectedThemeCodeNotifier extends StateNotifier<String> {
  final Ref _ref;

  SelectedThemeCodeNotifier(this._ref) : super('classic-theme-1') {
    // 默认为你好西大人主题
    _initialize();
  }

  Future<void> _initialize() async {
    final config = await _ref.read(themeConfigServiceProvider).loadConfig();
    state = config.selectedThemeCode;

    // 只有在主题对象为空且不是自定义主题时，才尝试加载主题对象
    // 并且不能影响主题模式
    if (config.selectedTheme == null && config.selectedThemeCode != 'custom') {
      AppLogger.debug(
        'SelectedThemeCodeNotifier: 配置中缺少主题对象，延迟加载: ${config.selectedThemeCode}',
      );
      // 使用延迟加载，避免在初始化期间修改配置
      Future.microtask(
        () => _ensureThemeObjectLoaded(config.selectedThemeCode),
      );
    }
  }

  Future<void> _ensureThemeObjectLoaded(String themeCode) async {
    try {
      AppLogger.debug('SelectedThemeCodeNotifier: 开始加载主题对象: $themeCode');

      // 等待主题列表加载完成
      final themes = await _ref.read(customThemesProvider.future);
      final foundTheme = themes.where((t) => t.code == themeCode);

      if (foundTheme.isNotEmpty) {
        final service = _ref.read(themeConfigServiceProvider);

        // 检查当前配置是否已经有正确的主题对象
        final currentConfig = await service.loadConfig();
        if (currentConfig.selectedTheme?.code != themeCode) {
          await service.selectTheme(themeCode, foundTheme.first);
          AppLogger.debug(
            'SelectedThemeCodeNotifier: 主题对象已加载: ${foundTheme.first.title} ($themeCode)',
          );
        } else {
          AppLogger.debug(
            'SelectedThemeCodeNotifier: 主题对象已存在: ${currentConfig.selectedTheme?.title} ($themeCode)',
          );
        }
      } else {
        AppLogger.debug('SelectedThemeCodeNotifier: 未找到主题 $themeCode');
        // 如果找不到指定主题，尝试加载第一个可用主题
        if (themes.isNotEmpty) {
          final firstTheme = themes.first;
          final service = _ref.read(themeConfigServiceProvider);
          await service.selectTheme(firstTheme.code, firstTheme);
          state = firstTheme.code;
          AppLogger.debug(
            'SelectedThemeCodeNotifier: 使用第一个可用主题: ${firstTheme.title} (${firstTheme.code})',
          );
        }
      }
    } catch (e) {
      AppLogger.debug('SelectedThemeCodeNotifier: 加载主题对象失败: $e');
    }
  }

  Future<void> setThemeCode(String themeCode) async {
    AppLogger.debug('SelectedThemeCodeNotifier: 开始切换主题到: $themeCode');

    final service = _ref.read(themeConfigServiceProvider);

    // 总是尝试获取主题对象（包括自定义主题）
    theme_model.Theme? theme;
    try {
      final themes = await _ref.read(customThemesProvider.future);
      final foundTheme = themes.where((t) => t.code == themeCode);
      theme = foundTheme.isNotEmpty ? foundTheme.first : null;

      if (theme != null) {
        AppLogger.debug(
          'SelectedThemeCodeNotifier: ✅ 找到主题对象: ${theme.title} ($themeCode)',
        );
        AppLogger.debug(
          'SelectedThemeCodeNotifier: 主题颜色: backColor=${theme.backColor}, foregColor=${theme.foregColor}, colorList=${theme.colorList.length}个颜色',
        );
      } else {
        AppLogger.debug('SelectedThemeCodeNotifier: ⚠️ 未找到主题对象: $themeCode');
      }
    } catch (e) {
      AppLogger.debug('SelectedThemeCodeNotifier: ❌ 获取主题列表失败: $e');
    }

    // 选择主题
    await service.selectTheme(themeCode, theme);
    AppLogger.debug('SelectedThemeCodeNotifier: ✅ 主题切换完成: $themeCode');

    final newConfig = await service.loadConfig();

    _ref.read(themeConfigNotifierProvider.notifier).state = AsyncValue.data(
      newConfig,
    );

    // 更新自己的 state
    state = newConfig.selectedThemeCode;

    AppLogger.debug('SelectedThemeCodeNotifier: ✅ 已更新配置（无闪烁）');
  }
}

/// 选中主题代码的状态管理提供者
final selectedThemeCodeNotifierProvider =
    StateNotifierProvider<SelectedThemeCodeNotifier, String>((ref) {
      return SelectedThemeCodeNotifier(ref);
    });

/// 自定义主题管理器
class CustomThemeManager
    extends StateNotifier<AsyncValue<List<theme_model.Theme>>> {
  final CustomThemeService _service;

  CustomThemeManager(this._service) : super(const AsyncValue.loading()) {
    loadThemes();
  }

  Future<void> loadThemes() async {
    try {
      state = const AsyncValue.loading();

      // 获取预设主题和自定义主题
      final customThemes = await _service.getCustomThemes();
      final presetThemes = await _loadPresetThemes();

      AppLogger.debug('CustomThemeManager: 加载主题列表');
      AppLogger.debug('  - 预设主题: ${presetThemes.length} 个');
      AppLogger.debug('  - 自定义主题: ${customThemes.length} 个');

      for (final theme in customThemes) {
        AppLogger.debug('    * ${theme.title} (${theme.code})');
      }

      // 检查是否支持系统动态主题（Android 12+）
      final dynamicColorService = DynamicColorService();
      if (!dynamicColorService.isInitialized) {
        await dynamicColorService.initialize();
      }

      List<theme_model.Theme> allThemes = [...presetThemes];

      // 如果支持动态颜色，添加系统动态主题到预设主题列表的开头
      if (dynamicColorService.isSupported) {
        final systemTheme = DynamicColorService().createSystemTheme();
        if (systemTheme != null) {
          allThemes.insert(0, systemTheme);
          AppLogger.debug('CustomThemeManager: ✅ 添加系统动态主题（Android 12+）');
        }
      }

      // 添加自定义主题
      allThemes.addAll(customThemes);

      state = AsyncValue.data(allThemes);

      AppLogger.debug('CustomThemeManager: ✅ 主题加载完成，共 ${allThemes.length} 个');
    } catch (e, st) {
      AppLogger.debug('CustomThemeManager: ❌ 加载主题失败: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<theme_model.Theme>> _loadPresetThemes() async {
    try {
      // 从assets加载预设主题
      final jsonStr = await rootBundle.loadString('assets/themes.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      return list
          .map((e) => theme_model.Theme.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 如果加载失败，返回默认主题
      return [_getDefaultTheme()];
    }
  }

  theme_model.Theme _getDefaultTheme() {
    // 你好西大人主题的标准配置（与themes.json保持一致）
    return theme_model.Theme(
      code: 'classic-theme-1',
      title: '你好西大人',
      img:
          'https://data.swu.social/service/external_files/2301371392301561862291631292311861844564564.webp',
      indexBackgroundBlur: false,
      indexBackgroundImg:
          'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
      indexMessageBoxBlur: true,
      backColor: Color.fromRGBO(35, 88, 168, 1), // 确保使用正确的RGB值
      foregColor: Color.fromRGBO(255, 255, 255, 1),
      weekColor: Color.fromRGBO(221, 221, 221, 1),
      classTableBackgroundBlur: false,
      colorList: [
        Color(0xFF2255a3),
        Color(0xFF2358a8),
        Color(0xFF275baa),
        Color(0xFF2c5fab),
        Color(0xFF3767b0),
        Color(0xFF3969b1),
        Color(0xFF3d6cb2),
        Color(0xFF426fb4),
        Color(0xFF4673b6),
        Color(0xFF4a76b7),
      ],
    );
  }

  Future<bool> deleteTheme(String themeCode) async {
    try {
      // 删除主题（单一数据源）
      await _service.deleteCustomTheme(themeCode);

      // 重新加载主题列表（触发响应式更新）
      await loadThemes();

      AppLogger.debug('CustomThemeManager: ✅ 已删除主题 $themeCode');
      return true;
    } catch (e) {
      AppLogger.debug('CustomThemeManager: ❌ 删除主题失败: $e');
      return false;
    }
  }

  Future<bool> saveTheme(theme_model.Theme theme) async {
    try {
      // 保存主题（单一数据源）
      await _service.saveCustomTheme(theme);

      // 重新加载主题列表（触发响应式更新）
      await loadThemes();

      AppLogger.debug('CustomThemeManager: ✅ 已保存主题 ${theme.title}');
      return true;
    } catch (e) {
      AppLogger.debug('CustomThemeManager: ❌ 保存主题失败: $e');
      return false;
    }
  }
}
