// lib/core/config/services/config_sync_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../services/api_service.dart';
import '../../../utils/common.dart';

/// 配置网络同步服务
/// 从旧的 ConfigService 迁移网络相关功能
/// 负责配置的上传下载、图片上传等网络操作
class ConfigSyncService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  ApiService? _apiService;

  ConfigSyncService({ApiService? apiService}) : _apiService = apiService;

  /// 设置API服务
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  /// 上传配置到服务器
  Future<void> uploadConfigs(Map<String, dynamic> configs) async {
    if (_apiService == null) {
      throw Exception('ApiService 未初始化');
    }

    try {
      debugPrint('ConfigSyncService: 开始上传配置...');

      // 处理配置中的图片上传
      final processedConfigs = await _processConfigImages(configs);

      // 上传到服务器
      await _apiService!.postConfigToServer(processedConfigs);
      debugPrint('ConfigSyncService: 配置上传成功');
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
      final user = await _secureStorage.read(key: 'userInfo');
      final fileName = "${randomSeedRange(0, 1000000000000000, int.tryParse(user ?? '0'))}-${const Uuid().v4()}.${imagePath.split('.').last}";
      
      final url = await _apiService!.uploadImage(imagePath, fileName);
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
  Future<Map<String, dynamic>> _processConfigImages(Map<String, dynamic> configs) async {
    final processedConfigs = Map<String, dynamic>.from(configs);

    // 处理主题配置中的背景图片
    if (processedConfigs['themeConfig'] != null) {
      final themeConfig = Map<String, dynamic>.from(processedConfigs['themeConfig']);
      
      if (themeConfig['selectedTheme'] != null && themeConfig['selectedTheme']['indexBackgroundImg'] != null) {
        final imageUrl = themeConfig['selectedTheme']['indexBackgroundImg'] as String;
        
        // 只上传本地图片，跳过已经是网络URL的图片
        if (!imageUrl.startsWith('https://data.swu.social') && 
            !imageUrl.startsWith('http://www.yumus.cn') &&
            !imageUrl.startsWith('http')) {
          try {
            final uploadedUrl = await uploadImage(imageUrl);
            themeConfig['selectedTheme']['indexBackgroundImg'] = uploadedUrl;
            processedConfigs['themeConfig'] = themeConfig;
            debugPrint('ConfigSyncService: 背景图片已上传并更新URL');
          } catch (e) {
            debugPrint('ConfigSyncService: 背景图片上传失败，保持原URL: $e');
          }
        }
      }

      // 处理自定义主题中的其他图片
      if (themeConfig['customTheme'] != null) {
        await _processCustomThemeImages(themeConfig['customTheme']);
      }
    }

    return processedConfigs;
  }

  /// 处理自定义主题中的图片
  Future<void> _processCustomThemeImages(Map<String, dynamic> customTheme) async {
    final imageFields = [
      'indexBackgroundImg',
      'classtableBackgroundImg', 
      'avatarImg',
      // 可以添加更多图片字段
    ];

    for (final field in imageFields) {
      if (customTheme[field] != null && customTheme[field] is String) {
        final imageUrl = customTheme[field] as String;
        
        if (!imageUrl.startsWith('http')) {
          try {
            final uploadedUrl = await uploadImage(imageUrl);
            customTheme[field] = uploadedUrl;
            debugPrint('ConfigSyncService: 自定义主题图片 $field 已上传');
          } catch (e) {
            debugPrint('ConfigSyncService: 自定义主题图片 $field 上传失败: $e');
          }
        }
      }
    }
  }

  /// 验证配置数据格式
  bool validateConfigFormat(Map<String, dynamic> configs) {
    try {
      // 基本格式验证
      if (!configs.containsKey('appConfig') || 
          !configs.containsKey('themeConfig') || 
          !configs.containsKey('userPreferences')) {
        return false;
      }

      // 可以添加更详细的验证逻辑
      return true;
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