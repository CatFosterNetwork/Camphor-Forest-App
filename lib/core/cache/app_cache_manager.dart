import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 全局图片缓存管理器，负责统一壁纸/大图缓存策略
/// 缓存过期时间设置为每天23:59分
class AppCacheManager extends CacheManager {
  AppCacheManager._()
    : super(
        Config(
          'appWallpaperCache',
          stalePeriod: const Duration(days: 1), // 基础1天过期
          maxNrOfCacheObjects: 30,
        ),
      );

  static final AppCacheManager instance = AppCacheManager._();

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final fileInfo = await super.getFileFromCache(
      key,
      ignoreMemCache: ignoreMemCache,
    );

    if (fileInfo != null) {
      // 检查文件是否已过23:59分
      if (_isFileExpiredAt2359(fileInfo.validTill)) {
        debugPrint('AppCacheManager: 缓存文件已过期(超过23:59), 删除缓存: $key');
        // 如果已过期，删除缓存并返回null
        await removeFile(key);
        return null;
      } else {
        debugPrint('AppCacheManager: 缓存文件有效, 使用缓存: $key');
      }
    }

    return fileInfo;
  }

  /// 检查文件是否已过期（基于每天23:59分的规则）
  bool _isFileExpiredAt2359(DateTime validTill) {
    final now = DateTime.now();

    // 计算文件的实际过期时间（当天23:59分）
    final fileCreatedDay = DateTime(
      validTill.year,
      validTill.month,
      validTill.day,
    );
    final expiryTime = DateTime(
      fileCreatedDay.year,
      fileCreatedDay.month,
      fileCreatedDay.day,
      23,
      59,
      59,
    );

    final isExpired = now.isAfter(expiryTime);

    debugPrint(
      'AppCacheManager: 检查过期时间 - 当前: $now, 过期时间: $expiryTime, 已过期: $isExpired',
    );

    // 如果当前时间超过了文件创建当天的23:59分，则过期
    return isExpired;
  }
}
