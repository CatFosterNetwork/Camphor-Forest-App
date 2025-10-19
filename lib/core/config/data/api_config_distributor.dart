// lib/core/config/data/api_config_distributor.dart

import '../../../core/utils/app_logger.dart';

import '../models/app_config.dart';
import '../models/theme_config.dart';
import '../models/user_preferences.dart';
import '../../models/theme_model.dart';

/// API配置数据分配器
/// 负责将从API获取的配置数据分配到各个配置管理系统
class ApiConfigDistributor {
  /// 将API配置数据分配到各个配置系统
  static ConfigDistributionResult distributeApiData(
    Map<String, dynamic> apiData,
  ) {
    try {
      AppLogger.debug('ApiConfigDistributor: 开始分配API配置数据...');

      // 规范化配置格式（统一转换为嵌套格式 ）
      final normalizedData = _normalizeConfigFormat(apiData);

      AppLogger.debug(
        'ApiConfigDistributor: 配置格式规范化完成，原格式: ${_detectConfigFormat(apiData)}, 目标格式: nested',
      );

      // 从嵌套格式分配应用配置
      final appConfig = _createAppConfig(normalizedData);

      // 从嵌套格式分配主题配置
      final themeConfig = _createThemeConfig(normalizedData);

      // 从嵌套格式分配用户偏好
      final userPreferences = _createUserPreferences(normalizedData);

      // 提取自定义主题列表（用于 CustomThemeService）
      final customThemes = _extractCustomThemes(normalizedData);

      AppLogger.debug('ApiConfigDistributor: 配置数据分配完成');
      return ConfigDistributionResult.success(
        appConfig: appConfig,
        themeConfig: themeConfig,
        userPreferences: userPreferences,
        customThemes: customThemes,
      );
    } catch (e, st) {
      AppLogger.debug('ApiConfigDistributor: 配置数据分配失败: $e');
      return ConfigDistributionResult.failure(e, st);
    }
  }

  /// 检测配置格式类型
  static String _detectConfigFormat(Map<String, dynamic> data) {
    // 检查是否为嵌套格式（包含 appConfig, themeConfig 等顶层键）
    if (data.containsKey('appConfig') ||
        data.containsKey('themeConfig') ||
        data.containsKey('userPreferences')) {
      return 'nested';
    }

    // 检查是否为扁平格式（包含 index-, forest-, theme- 前缀的键）
    final hasIndexKeys = data.keys.any((key) => key.startsWith('index-'));
    final hasForestKeys = data.keys.any((key) => key.startsWith('forest-'));
    final hasThemeKeys = data.keys.any((key) => key.startsWith('theme-'));

    if (hasIndexKeys || hasForestKeys || hasThemeKeys) {
      return 'flat';
    }

    return 'unknown';
  }

  /// 规范化配置格式（统一转换为嵌套格式）
  static Map<String, dynamic> _normalizeConfigFormat(
    Map<String, dynamic> data,
  ) {
    final format = _detectConfigFormat(data);

    if (format == 'nested') {
      AppLogger.debug('ApiConfigDistributor: 检测到嵌套格式，直接使用');
      return data;
    } else if (format == 'flat') {
      AppLogger.debug('ApiConfigDistributor: 检测到扁平格式，转换为嵌套格式...');
      return _convertFlatToNested(data);
    } else {
      AppLogger.debug('ApiConfigDistributor: 未知格式，尝试作为嵌套格式处理');
      return data;
    }
  }

  /// 将扁平格式转换为嵌套格式
  static Map<String, dynamic> _convertFlatToNested(Map<String, dynamic> flat) {
    final nested = <String, dynamic>{
      'appConfig': <String, dynamic>{},
      'themeConfig': <String, dynamic>{},
      'userPreferences': <String, dynamic>{},
    };

    // 分类字段
    for (final entry in flat.entries) {
      final key = entry.key;
      final value = entry.value;

      // 应用配置字段
      if (key.startsWith('index-') ||
          key.startsWith('forest-') ||
          key == 'autoSync' ||
          key == 'autoRenewalCheckInService' ||
          key == 'classTable-custom') {
        nested['appConfig'][key] = value;
      }
      // 主题配置字段
      else if (key.startsWith('theme-') || key == 'selectedThemeCode') {
        nested['themeConfig'][key] = value;
      }
      // 元数据字段保留在顶层
      else if (key.startsWith('_')) {
        nested[key] = value;
      }
      // 其他字段归入用户偏好
      else {
        nested['userPreferences'][key] = value;
      }
    }

    // 🔧 向后兼容：将单个 theme-customTheme 转换为 theme-customThemes 数组
    if (nested['themeConfig'].containsKey('theme-customTheme') &&
        !nested['themeConfig'].containsKey('theme-customThemes')) {
      final customTheme = nested['themeConfig']['theme-customTheme'];
      if (customTheme != null) {
        nested['themeConfig']['theme-customThemes'] = [customTheme];
        AppLogger.debug('ApiConfigDistributor: 将单个自定义主题转换为数组格式');
      }
      // 移除旧字段
      nested['themeConfig'].remove('theme-customTheme');
    }

    // 校验颜色模式：将 "auto" 映射为 "system"
    if (nested['themeConfig']['theme-colorMode'] == 'auto') {
      nested['themeConfig']['theme-colorMode'] = 'system';
      AppLogger.debug(
        'ApiConfigDistributor: [扁平转嵌套] 将颜色模式 "auto" 转换为 "system"',
      );
    }

    // 确保 selectedThemeCode 存在
    if (!nested['themeConfig'].containsKey('selectedThemeCode')) {
      // 检查是否使用自定义主题（微信端逻辑：title === "自定义"）
      final themeTheme = nested['themeConfig']['theme-theme'];
      final customThemes = nested['themeConfig']['theme-customThemes'];

      if (themeTheme != null &&
          themeTheme is Map &&
          themeTheme['title'] == '自定义' &&
          customThemes is List &&
          customThemes.isNotEmpty &&
          customThemes[0] is Map &&
          customThemes[0]['code'] != null) {
        // 使用自定义主题的 code
        nested['themeConfig']['selectedThemeCode'] = customThemes[0]['code'];
        AppLogger.debug(
          'ApiConfigDistributor: [扁平转嵌套] 检测到自定义主题，设置 selectedThemeCode = ${customThemes[0]['code']}',
        );
      } else if (themeTheme != null &&
          themeTheme is Map &&
          themeTheme['code'] != null) {
        // 使用预设主题的 code
        nested['themeConfig']['selectedThemeCode'] = themeTheme['code'];
      }
    }

    return nested;
  }

  /// 创建应用配置
  static AppConfig _createAppConfig(Map<String, dynamic> nestedData) {
    // 提取 appConfig 部分
    final appConfigData = nestedData['appConfig'] is Map
        ? nestedData['appConfig'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AppConfig(
      // 首页显示配置
      showFinishedTodo: _getBool(appConfigData, 'index-showFinishedTodo', true),
      showTodo: _getBool(appConfigData, 'index-showTodo', true),
      showExpense: _getBool(appConfigData, 'index-showExpense', true),
      showClassroom: _getBool(appConfigData, 'index-showClassroom', true),
      showExams: _getBool(appConfigData, 'index-showExams', true),
      showGrades: _getBool(appConfigData, 'index-showGrades', true),
      showIndexServices: _getBool(
        appConfigData,
        'index-showIndexServices',
        true,
      ),

      // 森林功能配置
      showFleaMarket: _getBool(appConfigData, 'forest-showFleaMarket', false),
      showCampusRecruitment: _getBool(
        appConfigData,
        'forest-showCampusRecruitment',
        false,
      ),
      showSchoolNavigation: _getBool(
        appConfigData,
        'forest-showSchoolNavigation',
        true,
      ),
      showLibrary: _getBool(appConfigData, 'forest-showLibrary', false),
      showBBS: _getBool(appConfigData, 'forest-showBBS', true),
      showAds: _getBool(appConfigData, 'forest-showAds', false),
      showLifeService: _getBool(appConfigData, 'forest-showLifeService', true),
      showFeedback: _getBool(appConfigData, 'forest-showFeedback', true),

      // 基础配置
      autoSync: _getBool(appConfigData, 'autoSync', false),
      autoRenewalCheckInService: _getBool(
        appConfigData,
        'autoRenewalCheckInService',
        false,
      ),
    );
  }

  /// 创建主题配置
  static ThemeConfig _createThemeConfig(Map<String, dynamic> nestedData) {
    // 提取 themeConfig 部分
    final themeConfigData = nestedData['themeConfig'] is Map
        ? nestedData['themeConfig'] as Map<String, dynamic>
        : <String, dynamic>{};

    // 解析主题数据
    Theme? selectedTheme;
    List<Theme> customThemes = [];

    // 校验颜色模式：将 "auto" 映射为 "system"
    if (themeConfigData['theme-colorMode'] == 'auto') {
      themeConfigData['theme-colorMode'] = 'system';
      AppLogger.debug('ApiConfigDistributor: 将颜色模式 "auto" 转换为 "system"');
    }

    // 获取 selectedThemeCode
    String selectedThemeCode = _getString(
      themeConfigData,
      'selectedThemeCode',
      'classic-theme-1',
    );

    // 如果API中有主题数据，解析它
    if (themeConfigData.containsKey('theme-theme') &&
        themeConfigData['theme-theme'] != null) {
      try {
        final themeData = Map<String, dynamic>.from(
          themeConfigData['theme-theme'],
        );

        // 如果主题数据中缺少 code，使用 selectedThemeCode
        if (!themeData.containsKey('code') || themeData['code'] == null) {
          themeData['code'] = selectedThemeCode;
          AppLogger.debug(
            'ApiConfigDistributor: 主题数据缺少 code 字段，使用 selectedThemeCode: $selectedThemeCode',
          );
        }

        selectedTheme = Theme.fromJson(themeData);

        // 🔧 检测微信端自定义主题逻辑：如果 title 是 "自定义"，说明用户选择了自定义主题
        if (themeData['title'] == '自定义') {
          AppLogger.debug('ApiConfigDistributor: 检测到微信端自定义主题（title=自定义）');
          // 标记需要使用自定义主题
          // selectedThemeCode 将在后面根据 customTheme 的 code 设置
        }
      } catch (e) {
        AppLogger.debug('ApiConfigDistributor: 解析选中主题失败: $e');
      }
    }

    // 🔧 解析自定义主题列表（支持新旧两种格式）
    if (themeConfigData.containsKey('theme-customThemes') &&
        themeConfigData['theme-customThemes'] is List) {
      // 新格式：数组
      try {
        customThemes = (themeConfigData['theme-customThemes'] as List)
            .map((themeJson) {
              try {
                return Theme.fromJson(themeJson as Map<String, dynamic>);
              } catch (e) {
                AppLogger.debug('ApiConfigDistributor: 解析自定义主题失败: $e');
                return null;
              }
            })
            .whereType<Theme>()
            .toList();
        AppLogger.debug(
          'ApiConfigDistributor: 成功解析 ${customThemes.length} 个自定义主题',
        );
      } catch (e) {
        AppLogger.debug('ApiConfigDistributor: 解析自定义主题列表失败: $e');
      }
    } else if (themeConfigData.containsKey('theme-customTheme') &&
        themeConfigData['theme-customTheme'] != null) {
      // 旧格式：单个对象 - 向后兼容
      try {
        final customThemeData = Map<String, dynamic>.from(
          themeConfigData['theme-customTheme'],
        );

        // 🔧 修复：自定义主题的 code 应该是 'custom'
        if (!customThemeData.containsKey('code') ||
            customThemeData['code'] == null) {
          customThemeData['code'] = 'custom';
        }

        customThemes = [Theme.fromJson(customThemeData)];
        AppLogger.debug('ApiConfigDistributor: 检测到旧格式单个自定义主题，已转换为列表');
      } catch (e) {
        AppLogger.debug('ApiConfigDistributor: 解析旧格式自定义主题失败: $e');
      }
    }

    // 🔧 修复微信端自定义主题选择逻辑
    // 如果 theme-theme.title 是 "自定义"，且有 customThemes，应该使用第一个自定义主题的 code
    if (selectedTheme != null &&
        selectedTheme.title == '自定义' &&
        customThemes.isNotEmpty) {
      final customThemeCode = customThemes[0].code;
      AppLogger.debug(
        'ApiConfigDistributor: 微信端使用自定义主题，更新 selectedThemeCode: $selectedThemeCode -> $customThemeCode',
      );
      selectedThemeCode = customThemeCode;
      // 用自定义主题替换 selectedTheme（因为 "自定义" 主题只是占位符）
      selectedTheme = customThemes[0];
    }

    return ThemeConfig(
      themeMode: _getString(themeConfigData, 'theme-colorMode', 'system'),
      isDarkMode: _getBool(themeConfigData, 'theme-darkMode', false),
      selectedTheme: selectedTheme,
      selectedThemeCode: selectedThemeCode,
    );
  }

  /// 创建用户偏好配置
  static UserPreferences _createUserPreferences(
    Map<String, dynamic> nestedData,
  ) {
    // 提取 userPreferences 部分
    final userPrefsData = nestedData['userPreferences'] is Map
        ? nestedData['userPreferences'] as Map<String, dynamic>
        : <String, dynamic>{};
    // 但如果API中有相关数据，也可以设置
    return UserPreferences(
      language: _getString(userPrefsData, 'language', 'zh-CN'),
      enableNotifications: _getBool(userPrefsData, 'enableNotifications', true),
      enableVibration: _getBool(userPrefsData, 'enableVibration', true),
      enableSound: _getBool(userPrefsData, 'enableSound', true),
      cacheLimit: _getInt(userPrefsData, 'cacheLimit', 100),
      enableDataSaver: _getBool(userPrefsData, 'enableDataSaver', false),
      isFirstLaunch: false, // 如果有API数据，说明不是首次启动
      customData: userPrefsData.containsKey('customUserData')
          ? Map<String, dynamic>.from(userPrefsData['customUserData'])
          : {},
    );
  }

  /// 提取自定义主题列表
  static List<Theme> _extractCustomThemes(Map<String, dynamic> nestedData) {
    // 提取 themeConfig 部分
    final themeConfigData = nestedData['themeConfig'] is Map
        ? nestedData['themeConfig'] as Map<String, dynamic>
        : <String, dynamic>{};

    List<Theme> customThemes = [];

    // 解析自定义主题列表（支持新旧两种格式）
    if (themeConfigData.containsKey('theme-customThemes') &&
        themeConfigData['theme-customThemes'] is List) {
      // 新格式：数组
      try {
        customThemes = (themeConfigData['theme-customThemes'] as List)
            .map((themeJson) {
              try {
                final theme = Theme.fromJson(themeJson as Map<String, dynamic>);
                // 🔧 过滤掉预设主题（防止服务器数据污染）
                if (theme.code.startsWith('classic-theme-')) {
                  AppLogger.debug(
                    'ApiConfigDistributor: 跳过预设主题 ${theme.code}（不应出现在 customThemes 中）',
                  );
                  return null;
                }
                return theme;
              } catch (e) {
                AppLogger.debug('ApiConfigDistributor: 解析自定义主题失败: $e');
                return null;
              }
            })
            .whereType<Theme>()
            .toList();
        AppLogger.debug(
          'ApiConfigDistributor: [提取] 自定义主题列表 - ${customThemes.length} 个',
        );
      } catch (e) {
        AppLogger.debug('ApiConfigDistributor: 提取自定义主题列表失败: $e');
      }
    } else if (themeConfigData.containsKey('theme-customTheme') &&
        themeConfigData['theme-customTheme'] != null) {
      // 旧格式：单个对象 - 向后兼容
      try {
        final customThemeData = Map<String, dynamic>.from(
          themeConfigData['theme-customTheme'],
        );

        // 🔧 修复：自定义主题的 code 应该是 'custom'
        if (!customThemeData.containsKey('code') ||
            customThemeData['code'] == null) {
          customThemeData['code'] = 'custom';
        }

        customThemes = [Theme.fromJson(customThemeData)];
        AppLogger.debug('ApiConfigDistributor: [提取] 检测到旧格式单个自定义主题');
      } catch (e) {
        AppLogger.debug('ApiConfigDistributor: 提取旧格式自定义主题失败: $e');
      }
    }

    return customThemes;
  }

  /// 创建空的配置（当API数据不可用时）
  static ConfigDistributionResult createDefaultConfigs() {
    AppLogger.debug('ApiConfigDistributor: 创建默认配置');
    return ConfigDistributionResult.success(
      appConfig: AppConfig.defaultConfig,
      themeConfig: ThemeConfig.defaultConfig,
      userPreferences: UserPreferences.defaultConfig,
    );
  }

  /// 验证API数据格式
  static bool validateApiData(Map<String, dynamic> apiData) {
    final format = _detectConfigFormat(apiData);

    if (format == 'nested') {
      // 验证嵌套格式
      if (!apiData.containsKey('appConfig') || apiData['appConfig'] is! Map) {
        AppLogger.debug('ApiConfigDistributor: 缺少 appConfig 部分');
        return false;
      }
      if (!apiData.containsKey('themeConfig') ||
          apiData['themeConfig'] is! Map) {
        AppLogger.debug('ApiConfigDistributor: 缺少 themeConfig 部分');
        return false;
      }
      return true;
    } else if (format == 'flat') {
      // 验证扁平格式
      final requiredKeys = [
        'index-showTodo',
        'forest-showBBS',
        'theme-colorMode',
      ];

      for (final key in requiredKeys) {
        if (!apiData.containsKey(key)) {
          AppLogger.debug('ApiConfigDistributor: 缺少必要配置项: $key');
          return false;
        }
      }
      return true;
    } else {
      AppLogger.debug('ApiConfigDistributor: 未知的配置格式');
      return false;
    }
  }

  /// 获取配置项统计
  static Map<String, int> getConfigStats(Map<String, dynamic> apiData) {
    int appConfigCount = 0;
    int themeConfigCount = 0;
    int userPrefCount = 0;

    final format = _detectConfigFormat(apiData);

    if (format == 'nested') {
      // 嵌套格式统计
      if (apiData['appConfig'] is Map) {
        appConfigCount = (apiData['appConfig'] as Map).length;
      }
      if (apiData['themeConfig'] is Map) {
        themeConfigCount = (apiData['themeConfig'] as Map).length;
      }
      if (apiData['userPreferences'] is Map) {
        userPrefCount = (apiData['userPreferences'] as Map).length;
      }
    } else {
      // 扁平格式统计
      for (final key in apiData.keys) {
        if (key.startsWith('index-') ||
            key.startsWith('forest-') ||
            key == 'autoSync' ||
            key == 'autoRenewalCheckInService') {
          appConfigCount++;
        } else if (key.startsWith('theme-') || key == 'selectedThemeCode') {
          themeConfigCount++;
        } else if (!key.startsWith('_')) {
          userPrefCount++;
        }
      }
    }

    return {
      'appConfig': appConfigCount,
      'themeConfig': themeConfigCount,
      'userPreferences': userPrefCount,
      'total': appConfigCount + themeConfigCount + userPrefCount,
    };
  }

  /// 检查配置完整性（支持嵌套和扁平格式）
  /// 返回缺失的关键字段列表
  static List<String> checkConfigIntegrity(Map<String, dynamic> apiData) {
    final missingFields = <String>[];
    final format = _detectConfigFormat(apiData);

    // 必需的应用配置字段
    final requiredAppFields = [
      'index-showTodo',
      'index-showExpense',
      'forest-showBBS',
      'forest-showFeedback',
    ];

    // 必需的主题配置字段
    final requiredThemeFields = ['theme-colorMode', 'selectedThemeCode'];

    if (format == 'nested') {
      // 检查嵌套格式
      final appConfig = apiData['appConfig'] is Map
          ? apiData['appConfig'] as Map<String, dynamic>
          : <String, dynamic>{};
      final themeConfig = apiData['themeConfig'] is Map
          ? apiData['themeConfig'] as Map<String, dynamic>
          : <String, dynamic>{};

      // 检查应用配置
      for (final field in requiredAppFields) {
        if (!appConfig.containsKey(field)) {
          missingFields.add('appConfig.$field');
        }
      }

      // 检查主题配置
      for (final field in requiredThemeFields) {
        if (!themeConfig.containsKey(field)) {
          missingFields.add('themeConfig.$field');
        }
      }
    } else {
      // 检查扁平格式
      final allRequiredFields = [...requiredAppFields, ...requiredThemeFields];
      for (final field in allRequiredFields) {
        if (!apiData.containsKey(field)) {
          missingFields.add(field);
        }
      }
    }

    if (missingFields.isNotEmpty) {
      AppLogger.debug(
        'ApiConfigDistributor: 检测到缺失字段 ($format): ${missingFields.join(", ")}',
      );
    }

    return missingFields;
  }

  /// 修复配置数据（填充缺失的关键字段，支持嵌套和扁平格式）
  static Map<String, dynamic> repairConfigData(Map<String, dynamic> apiData) {
    final repairedData = Map<String, dynamic>.from(apiData);
    final missingFields = checkConfigIntegrity(apiData);

    if (missingFields.isEmpty) {
      AppLogger.debug('ApiConfigDistributor: 配置数据完整，无需修复');
      return repairedData;
    }

    AppLogger.debug(
      'ApiConfigDistributor: 开始修复 ${missingFields.length} 个缺失字段...',
    );

    final format = _detectConfigFormat(apiData);
    final defaultConfig = AppConfig.defaultConfig.toJson();
    final defaultTheme = ThemeConfig.defaultConfig.toJson();

    if (format == 'nested') {
      // 修复嵌套格式
      if (!repairedData.containsKey('appConfig')) {
        repairedData['appConfig'] = <String, dynamic>{};
      }
      if (!repairedData.containsKey('themeConfig')) {
        repairedData['themeConfig'] = <String, dynamic>{};
      }
      if (!repairedData.containsKey('userPreferences')) {
        repairedData['userPreferences'] = <String, dynamic>{};
      }

      final appConfig = repairedData['appConfig'] as Map<String, dynamic>;
      final themeConfig = repairedData['themeConfig'] as Map<String, dynamic>;

      for (final field in missingFields) {
        if (field.startsWith('appConfig.')) {
          final key = field.substring('appConfig.'.length);
          if (defaultConfig.containsKey(key)) {
            appConfig[key] = defaultConfig[key];
            AppLogger.debug(
              'ApiConfigDistributor: 填充 $field = ${defaultConfig[key]}',
            );
          }
        } else if (field.startsWith('themeConfig.')) {
          final key = field.substring('themeConfig.'.length);

          // 🔧 特殊处理：selectedThemeCode 应该从 theme-theme.code 读取
          if (key == 'selectedThemeCode' &&
              themeConfig.containsKey('theme-theme')) {
            try {
              final themeTheme = themeConfig['theme-theme'];
              if (themeTheme is Map && themeTheme.containsKey('code')) {
                themeConfig[key] = themeTheme['code'];
                AppLogger.debug(
                  'ApiConfigDistributor: 填充 $field = ${themeTheme['code']} (从 theme-theme.code 读取)',
                );
                continue;
              }
            } catch (e) {
              AppLogger.debug(
                'ApiConfigDistributor: 从 theme-theme.code 读取失败: $e',
              );
            }
          }

          if (defaultTheme.containsKey(key)) {
            themeConfig[key] = defaultTheme[key];
            AppLogger.debug(
              'ApiConfigDistributor: 填充 $field = ${defaultTheme[key]}',
            );
          }
        }
      }
    } else {
      // 修复扁平格式
      for (final field in missingFields) {
        // 🔧 特殊处理：selectedThemeCode 应该从 theme-theme.code 读取
        if (field == 'selectedThemeCode' &&
            repairedData.containsKey('theme-theme')) {
          try {
            final themeTheme = repairedData['theme-theme'];
            if (themeTheme is Map && themeTheme.containsKey('code')) {
              repairedData[field] = themeTheme['code'];
              AppLogger.debug(
                'ApiConfigDistributor: 填充 $field = ${themeTheme['code']} (从 theme-theme.code 读取)',
              );
              continue;
            }
          } catch (e) {
            AppLogger.debug(
              'ApiConfigDistributor: 从 theme-theme.code 读取失败: $e',
            );
          }
        }

        if (defaultConfig.containsKey(field)) {
          repairedData[field] = defaultConfig[field];
          AppLogger.debug(
            'ApiConfigDistributor: 填充 $field = ${defaultConfig[field]}',
          );
        } else if (defaultTheme.containsKey(field)) {
          repairedData[field] = defaultTheme[field];
          AppLogger.debug(
            'ApiConfigDistributor: 填充 $field = ${defaultTheme[field]}',
          );
        }
      }
    }

    AppLogger.debug('ApiConfigDistributor: 配置数据修复完成');
    return repairedData;
  }

  // ===== 辅助方法 =====

  /// 安全获取布尔值
  static bool _getBool(
    Map<String, dynamic> data,
    String key,
    bool defaultValue,
  ) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// 安全获取字符串值
  static String _getString(
    Map<String, dynamic> data,
    String key,
    String defaultValue,
  ) {
    final value = data[key];
    return value is String ? value : defaultValue;
  }

  /// 安全获取整数值
  static int _getInt(Map<String, dynamic> data, String key, int defaultValue) {
    final value = data[key];
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is double) return value.round();
    return defaultValue;
  }
}

/// 配置分配结果
class ConfigDistributionResult {
  final bool success;
  final String message;
  final AppConfig? appConfig;
  final ThemeConfig? themeConfig;
  final UserPreferences? userPreferences;
  final List<Theme>? customThemes; // 自定义主题列表
  final Object? error;
  final StackTrace? stackTrace;

  const ConfigDistributionResult._({
    required this.success,
    required this.message,
    this.appConfig,
    this.themeConfig,
    this.userPreferences,
    this.customThemes,
    this.error,
    this.stackTrace,
  });

  /// 成功的分配结果
  factory ConfigDistributionResult.success({
    required AppConfig appConfig,
    required ThemeConfig themeConfig,
    required UserPreferences userPreferences,
    List<Theme>? customThemes,
  }) {
    return ConfigDistributionResult._(
      success: true,
      message: '配置数据分配成功',
      appConfig: appConfig,
      themeConfig: themeConfig,
      userPreferences: userPreferences,
      customThemes: customThemes,
    );
  }

  /// 失败的分配结果
  factory ConfigDistributionResult.failure(
    Object error,
    StackTrace stackTrace,
  ) {
    return ConfigDistributionResult._(
      success: false,
      message: '配置数据分配失败: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'ConfigDistributionResult{success: $success, message: $message}';
  }
}
