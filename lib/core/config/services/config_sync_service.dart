// lib/core/config/services/config_sync_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/api_service.dart';
import '../../services/image_upload_service.dart';

/// 配置网络同步服务
/// 从旧的 ConfigService 迁移网络相关功能
/// 负责配置的上传下载、图片上传等网络操作
class ConfigSyncService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  ApiService? _apiService;
  ImageUploadService? _imageUploadService;

  ConfigSyncService({
    ApiService? apiService,
    ImageUploadService? imageUploadService,
  }) : _apiService = apiService,
       _imageUploadService = imageUploadService;

  /// 设置API服务
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  /// 设置图片上传服务
  void setImageUploadService(ImageUploadService imageUploadService) {
    _imageUploadService = imageUploadService;
  }

  /// 上传配置到服务器
  /// 返回处理后的配置（图片路径已替换为URL）
  Future<Map<String, dynamic>> uploadConfigs(
    Map<String, dynamic> configs,
  ) async {
    if (_apiService == null) {
      throw Exception('ApiService 未初始化');
    }

    try {
      debugPrint('ConfigSyncService: 开始上传配置...');

      // 处理配置中的图片上传（本地路径会被替换为URL）
      final processedConfigs = await _processConfigImages(configs);

      // 上传到服务器
      await _apiService!.postConfigToServer(processedConfigs);
      debugPrint('ConfigSyncService: 配置上传成功');

      // 返回处理后的配置，包含已上传的图片URL
      return processedConfigs;
    } catch (e) {
      debugPrint('ConfigSyncService: 配置上传失败: $e');
      rethrow;
    }
  }

  /// 从服务器下载配置
  Future<Map<String, dynamic>> downloadConfigs() async {
    if (_apiService == null) {
      throw Exception('ApiService 未初始化');
    }

    try {
      debugPrint('ConfigSyncService: 开始下载配置...');

      final response = await _apiService!.getConfig();
      if (response['data']?['settings'] != null) {
        final configs = response['data']['settings'] as Map<String, dynamic>;
        debugPrint('ConfigSyncService: 配置下载成功');
        return configs;
      } else {
        debugPrint('ConfigSyncService: 服务器无配置数据');
        return {};
      }
    } catch (e) {
      debugPrint('ConfigSyncService: 配置下载失败: $e');
      rethrow;
    }
  }

  /// 上传图片文件
  Future<String> uploadImage(String imagePath) async {
    if (_apiService == null) {
      throw Exception('ApiService 未初始化');
    }

    try {
      // 使用 ImageUploadService 上传图片
      final imageUploadService =
          _imageUploadService ?? ImageUploadService(_apiService!);

      // 使用用户信息创建上传上下文
      final user = await _secureStorage.read(key: 'userInfo');
      final context = user != null
          ? ImageUploadContext.fromUserId(user)
          : ImageUploadContext.empty();

      final url = await imageUploadService.uploadImage(
        imagePath,
        context: context,
        prefix: 'theme',
      );

      debugPrint('ConfigSyncService: 图片上传成功: $url');
      return url;
    } catch (e) {
      debugPrint('ConfigSyncService: 图片上传失败: $e');
      rethrow;
    }
  }

  /// 检查网络连接状态
  Future<bool> checkConnection() async {
    if (_apiService == null) return false;

    try {
      // 简单的连接测试，可以ping一个轻量级的API
      await _apiService!.getConfig();
      return true;
    } catch (e) {
      debugPrint('ConfigSyncService: 网络连接检查失败: $e');
      return false;
    }
  }

  /// 获取服务器配置版本
  Future<String?> getServerConfigVersion() async {
    if (_apiService == null) return null;

    try {
      final response = await _apiService!.getConfig();
      return response['data']?['version'] as String?;
    } catch (e) {
      debugPrint('ConfigSyncService: 获取服务器配置版本失败: $e');
      return null;
    }
  }

  // ===== 私有方法 =====

  /// 处理配置中的图片上传
  /// 优先处理嵌套格式，兼容扁平格式
  Future<Map<String, dynamic>> _processConfigImages(
    Map<String, dynamic> configs,
  ) async {
    final processedConfigs = Map<String, dynamic>.from(configs);

    // 检测配置格式
    final isNested =
        processedConfigs.containsKey('themeConfig') ||
        processedConfigs.containsKey('appConfig');

    if (isNested) {
      // 嵌套格式处理（标准格式）
      debugPrint('ConfigSyncService: 处理嵌套格式的图片...');

      if (processedConfigs['themeConfig'] != null) {
        final themeConfig = Map<String, dynamic>.from(
          processedConfigs['themeConfig'],
        );

        // 处理 theme-theme
        if (themeConfig['theme-theme'] != null &&
            themeConfig['theme-theme'] is Map) {
          await _processThemeImages(themeConfig['theme-theme']);
        } else {
          debugPrint('ConfigSyncService: ⚠️ theme-theme 不存在或格式错误');
        }

        // 处理 theme-customThemes（多个自定义主题）
        if (themeConfig['theme-customThemes'] != null &&
            themeConfig['theme-customThemes'] is List) {
          final customThemes = themeConfig['theme-customThemes'] as List;
          for (int i = 0; i < customThemes.length; i++) {
            if (customThemes[i] is Map) {
              await _processThemeImages(customThemes[i]);
            }
          }
          debugPrint('ConfigSyncService: 处理了 ${customThemes.length} 个自定义主题的图片');
        }
        // 处理旧格式 theme-customTheme（单个）
        else if (themeConfig['theme-customTheme'] != null &&
            themeConfig['theme-customTheme'] is Map) {
          await _processThemeImages(themeConfig['theme-customTheme']);
          debugPrint('ConfigSyncService: 检测到旧格式单个自定义主题');
        }

        processedConfigs['themeConfig'] = themeConfig;
      }
    } else {
      // 扁平格式处理
      debugPrint('ConfigSyncService: 处理扁平格式的图片...');

      // 处理 theme-customTheme
      if (processedConfigs['theme-customTheme'] != null &&
          processedConfigs['theme-customTheme'] is Map) {
        final customTheme = Map<String, dynamic>.from(
          processedConfigs['theme-customTheme'] as Map<String, dynamic>,
        );
        await _processThemeImages(customTheme);
        processedConfigs['theme-customTheme'] = customTheme;
      }

      // 处理 theme-theme
      if (processedConfigs['theme-theme'] != null &&
          processedConfigs['theme-theme'] is Map) {
        final theme = Map<String, dynamic>.from(
          processedConfigs['theme-theme'] as Map<String, dynamic>,
        );
        await _processThemeImages(theme);
        processedConfigs['theme-theme'] = theme;
      }
    }

    return processedConfigs;
  }

  /// 处理主题对象中的图片
  Future<void> _processThemeImages(Map<String, dynamic> theme) async {
    final imageFields = ['indexBackgroundImg', 'img'];

    for (final field in imageFields) {
      if (theme[field] != null && theme[field] is String) {
        final imageUrl = theme[field] as String;

        // 只上传本地图片，跳过已经是网络URL的图片
        if (!imageUrl.startsWith('https://data.swu.social') &&
            !imageUrl.startsWith('http://www.yumus.cn') &&
            !imageUrl.startsWith('http')) {
          debugPrint('ConfigSyncService: ⚠️ 发现本地图片: $field');
          debugPrint('ConfigSyncService: ⚠️ 路径: $imageUrl');

          try {
            final uploadedUrl = await uploadImage(imageUrl);
            theme[field] = uploadedUrl;
            debugPrint('ConfigSyncService: ✅ 主题图片 $field 已上传: $uploadedUrl');
          } catch (e) {
            // 图片上传失败，抛出错误阻止配置上传
            debugPrint('ConfigSyncService: ❌ 主题图片 $field 上传失败: $e');
            // 直接抛出原始错误，保留详细的错误信息
            rethrow;
          }
        }
      }
    }
  }

  /// 验证配置数据格式
  /// 支持扁平格式（微信）和嵌套格式（Flutter）
  bool validateConfigFormat(Map<String, dynamic> configs) {
    try {
      // 检查是否为嵌套格式
      final hasNestedStructure =
          configs.containsKey('appConfig') ||
          configs.containsKey('themeConfig') ||
          configs.containsKey('userPreferences');

      if (hasNestedStructure) {
        debugPrint('ConfigSyncService: 验证嵌套格式配置');
        return true;
      }

      // 检查是否为扁平格式（微信兼容格式）
      final hasIndexKeys = configs.keys.any((key) => key.startsWith('index-'));
      final hasForestKeys = configs.keys.any(
        (key) => key.startsWith('forest-'),
      );
      final hasThemeKeys = configs.keys.any((key) => key.startsWith('theme-'));

      if (hasIndexKeys || hasForestKeys || hasThemeKeys) {
        debugPrint('ConfigSyncService: 验证扁平格式配置');
        return true;
      }

      // 如果都不是，可能是空配置或格式错误
      debugPrint('ConfigSyncService: 未识别的配置格式');
      return configs.isEmpty; // 空配置也视为有效
    } catch (e) {
      debugPrint('ConfigSyncService: 配置格式验证失败: $e');
      return false;
    }
  }

  /// 获取同步统计信息
  Map<String, dynamic> getSyncStats(Map<String, dynamic> configs) {
    int totalFields = 0;
    int imageFields = 0;

    void countFields(Map<String, dynamic> obj, String prefix) {
      obj.forEach((key, value) {
        totalFields++;
        if (value is String &&
            (key.toLowerCase().contains('image') ||
                key.toLowerCase().contains('img') ||
                key.toLowerCase().contains('background'))) {
          imageFields++;
        } else if (value is Map<String, dynamic>) {
          countFields(value, '$prefix.$key');
        }
      });
    }

    countFields(configs, '');

    return {
      'totalFields': totalFields,
      'imageFields': imageFields,
      'configSections': configs.keys.length,
      'estimatedSize': jsonEncode(configs).length,
    };
  }
}
