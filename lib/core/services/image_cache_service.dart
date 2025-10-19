// lib/core/services/image_cache_service.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../utils/file_utils.dart';

/// 图片缓存服务
/// 负责缓存网络图片和本地资源，避免重复加载和闪烁
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Dio _dio = Dio();
  final Map<String, String> _urlToFileMap = {};
  final Map<String, ImageProvider> _imageProviderCache = {};
  late Directory _cacheDir;
  bool _initialized = false;

  /// 初始化缓存服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/image_cache');

      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }

      _initialized = true;
      AppLogger.debug('🖼️ ImageCacheService initialized: ${_cacheDir.path}');
    } catch (e) {
      AppLogger.debug('❌ Failed to initialize ImageCacheService: $e');
    }
  }

  /// 生成URL的缓存文件名
  String _generateCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    final extension = FileUtils.getFileExtensionFromUrl(url);
    return '${digest.toString()}$extension';
  }

  /// 获取缓存文件路径
  String _getCacheFilePath(String url) {
    final fileName = _generateCacheFileName(url);
    return '${_cacheDir.path}/$fileName';
  }

  /// 检查文件是否已缓存
  Future<bool> isCached(String url) async {
    if (!_initialized) await initialize();

    final filePath = _getCacheFilePath(url);
    final file = File(filePath);
    return await file.exists();
  }

  /// 下载并缓存图片
  Future<String?> _downloadAndCache(String url) async {
    if (!_initialized) await initialize();

    try {
      final filePath = _getCacheFilePath(url);
      final file = File(filePath);

      AppLogger.debug('🌐 Downloading image: $url');

      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': 'CamphorForest/1.0'},
        ),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.data);
        _urlToFileMap[url] = filePath;

        AppLogger.debug('✅ Image cached: $filePath');
        return filePath;
      }
    } catch (e) {
      AppLogger.debug('❌ Failed to download image $url: $e');
    }

    return null;
  }

  /// 获取缓存的图片提供者
  Future<ImageProvider?> getCachedImageProvider(String url) async {
    if (!_initialized) await initialize();

    // 首先检查内存缓存
    if (_imageProviderCache.containsKey(url)) {
      return _imageProviderCache[url];
    }

    // 检查磁盘缓存
    final filePath = _getCacheFilePath(url);
    final file = File(filePath);

    if (await file.exists()) {
      final provider = FileImage(file);
      _imageProviderCache[url] = provider;
      return provider;
    }

    // 如果没有缓存，下载并缓存
    final cachedPath = await _downloadAndCache(url);
    if (cachedPath != null) {
      final provider = FileImage(File(cachedPath));
      _imageProviderCache[url] = provider;
      return provider;
    }

    return null;
  }

  /// 预缓存图片
  Future<void> precacheImage(String url) async {
    if (!_initialized) await initialize();

    if (await isCached(url)) {
      AppLogger.debug('🎯 Image already cached: $url');
      return;
    }

    await _downloadAndCache(url);
  }

  /// 预缓存多个图片
  Future<void> precacheImages(List<String> urls) async {
    final futures = urls.map((url) => precacheImage(url));
    await Future.wait(futures);
  }

  /// 清理过期缓存
  Future<void> cleanExpiredCache({
    Duration maxAge = const Duration(days: 7),
  }) async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDir.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age > maxAge) {
            await file.delete();
            AppLogger.debug('🗑️ Deleted expired cache: ${file.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.debug('❌ Failed to clean cache: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDir.list().toList();
      int totalSize = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      AppLogger.debug('❌ Failed to get cache size: $e');
      return 0;
    }
  }

  /// 清空所有缓存
  Future<void> clearAllCache() async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDir.list().toList();

      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }

      _urlToFileMap.clear();
      _imageProviderCache.clear();

      AppLogger.debug('🗑️ All image cache cleared');
    } catch (e) {
      AppLogger.debug('❌ Failed to clear cache: $e');
    }
  }

  /// 从缓存中移除特定URL
  Future<void> removeFromCache(String url) async {
    if (!_initialized) await initialize();

    try {
      final filePath = _getCacheFilePath(url);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      _urlToFileMap.remove(url);
      _imageProviderCache.remove(url);

      AppLogger.debug('🗑️ Removed from cache: $url');
    } catch (e) {
      AppLogger.debug('❌ Failed to remove from cache: $e');
    }
  }

  /// 预加载启动时需要的图片
  Future<void> preloadStartupImages() async {
    AppLogger.debug('🚀 Preloading startup images...');

    // 预加载关于页面的QR码图片
    final qrImages = [
      'https://data.swu.social/service/qrcode_dark.JPG',
      'https://data.swu.social/service/qrcode_light.JPG',
    ];

    await precacheImages(qrImages);

    AppLogger.debug('✅ Startup images preloaded');
  }
}
