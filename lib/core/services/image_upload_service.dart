// lib/core/services/image_upload_service.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'api_service.dart';
import '../utils/file_utils.dart';

/// 图片上传服务
/// 统一管理图片上传逻辑和文件名生成
class ImageUploadService {
  final ApiService _apiService;

  ImageUploadService(this._apiService);

  /// 上传单张图片
  ///
  /// [imagePath] 本地图片路径
  /// [context] 上传上下文（用于生成文件名）
  /// [prefix] 文件名前缀（可选）
  /// [maxRetries] 最大重试次数（默认3次）
  ///
  /// 返回：上传成功后的图片URL
  Future<String> uploadImage(
    String imagePath, {
    ImageUploadContext? context,
    String? prefix,
    int maxRetries = 3,
  }) async {
    debugPrint('📸 ImageUploadService: 开始上传图片');
    debugPrint('📄 本地路径: $imagePath');

    // 检查文件是否存在
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('图片文件不存在: $imagePath');
    }

    // 检查文件大小（5MB 限制）
    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1000 * 1000);
    debugPrint('ImageUploadService: 图片大小: ${fileSizeMB.toStringAsFixed(2)} MB');

    if (fileSizeMB > 5) {
      throw Exception(
        '图片体积过大！\n'
        '文件: $imagePath\n'
        '当前上传图片大小: ${fileSizeMB.toStringAsFixed(2)} MB\n'
        '单张图片体积最大限制: 5 MB',
      );
    }

    // 生成文件名
    final fileName = _generateFileName(
      imagePath,
      context: context,
      prefix: prefix,
    );
    debugPrint('📝 生成文件名: $fileName');

    // 带重试的上传
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('🔄 第 $attempt 次重试上传...');
          // 重试前等待（指数退避）
          await Future.delayed(Duration(seconds: attempt * 2));
        }

        final url = await _apiService.uploadImage(imagePath, fileName);
        debugPrint('✅ ImageUploadService: 图片上传成功');
        debugPrint('🌐 URL: $url');

        return url;
      } catch (e) {
        debugPrint('❌ ImageUploadService: 第 $attempt 次上传失败');
        debugPrint('❌ 错误: $e');

        // 最后一次尝试失败，抛出异常
        if (attempt == maxRetries) {
          debugPrint('💥 ImageUploadService: 已达最大重试次数，上传失败');
          rethrow;
        }

        // 检查是否是网络错误，如果不是则不重试
        final errorStr = e.toString().toLowerCase();
        if (!errorStr.contains('socket') &&
            !errorStr.contains('connection') &&
            !errorStr.contains('timeout')) {
          debugPrint('⚠️ ImageUploadService: 非网络错误，不再重试');
          rethrow;
        }
      }
    }

    // 理论上不会到这里
    throw Exception('图片上传失败');
  }

  /// 批量上传图片
  ///
  /// [imagePaths] 本地图片路径列表
  /// [context] 上传上下文
  /// [prefix] 文件名前缀（可选）
  ///
  /// 返回：Map<index, url> 索引到URL的映射
  Future<Map<int, String>> uploadImages(
    List<String> imagePaths, {
    ImageUploadContext? context,
    String? prefix,
    void Function(int index, int total)? onProgress,
  }) async {
    final results = <int, String>{};

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        debugPrint('📸 ImageUploadService: 上传图片 ${i + 1}/${imagePaths.length}');

        final url = await uploadImage(
          imagePaths[i],
          context: context,
          prefix: prefix != null ? '${prefix}_$i' : null,
        );

        results[i] = url;
        onProgress?.call(i + 1, imagePaths.length);
      } catch (e) {
        debugPrint('❌ ImageUploadService: 图片 $i 上传失败: $e');
        rethrow;
      }
    }

    return results;
  }

  /// 生成文件名
  ///
  /// 格式: [prefix_]randomNum-uuid.extension
  /// 例如: feedback_123456789-a1b2c3d4.jpg
  String _generateFileName(
    String imagePath, {
    ImageUploadContext? context,
    String? prefix,
  }) {
    final extension = FileUtils.getFileExtension(imagePath);
    final randomNum = _generateRandomNumber(context?.seed);
    final uuid = _generateUuid();

    final parts = [if (prefix != null) prefix, '$randomNum-$uuid'];

    return '${parts.join('_')}.$extension';
  }

  /// 生成随机数（安全范围内）
  ///
  /// 最大值为 999,999,999 (约10亿)，远小于 Dart Random 的限制 2^32
  int _generateRandomNumber([int? seed]) {
    final random = seed != null ? Random(seed) : Random();
    return random.nextInt(999999999);
  }

  /// 生成 UUID (8位短UUID)
  String _generateUuid() {
    return const Uuid().v4().substring(0, 8);
  }
}

/// 图片上传上下文
/// 提供文件名生成所需的上下文信息
class ImageUploadContext {
  /// 用于生成随机数的种子
  final int? seed;

  /// 用户ID或学号
  final String? userId;

  /// 时间戳（用于排序）
  final int? timestamp;

  const ImageUploadContext({this.seed, this.userId, this.timestamp});

  /// 从学号创建上下文
  factory ImageUploadContext.fromStudentId(String studentId) {
    return ImageUploadContext(
      seed: int.tryParse(studentId),
      userId: studentId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 从用户ID创建上下文
  factory ImageUploadContext.fromUserId(String userId) {
    return ImageUploadContext(
      seed: userId.hashCode,
      userId: userId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 创建空上下文
  factory ImageUploadContext.empty() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ImageUploadContext(seed: now % 999999999, timestamp: now);
  }
}
