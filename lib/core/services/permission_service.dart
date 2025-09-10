// lib/core/services/permission_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

/// 权限类型枚举
enum AppPermissionType {
  /// 相册权限（读取照片）
  photos,

  /// 相机权限（拍照）
  camera,

  /// 存储权限（Android 12及以下）
  storage,

  /// 通知权限
  notification,

  /// 位置权限
  location,
}

/// 权限状态扩展
extension AppPermissionTypeExtension on AppPermissionType {
  /// 获取对应的permission_handler权限
  Permission get permission {
    switch (this) {
      case AppPermissionType.photos:
        return Permission.photos;
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.storage:
        return Permission.storage;
      case AppPermissionType.notification:
        return Permission.notification;
      case AppPermissionType.location:
        return Permission.location;
    }
  }

  /// 获取权限的中文名称
  String get displayName {
    switch (this) {
      case AppPermissionType.photos:
        return '照片权限';
      case AppPermissionType.camera:
        return '相机权限';
      case AppPermissionType.storage:
        return '存储权限';
      case AppPermissionType.notification:
        return '通知权限';
      case AppPermissionType.location:
        return '位置权限';
    }
  }

  /// 获取权限的详细说明
  String get description {
    switch (this) {
      case AppPermissionType.photos:
        return '需要访问您的照片库来选择和保存图片';
      case AppPermissionType.camera:
        return '需要使用相机来拍摄照片';
      case AppPermissionType.storage:
        return '需要访问设备存储来保存文件';
      case AppPermissionType.notification:
        return '需要发送通知来提醒您重要信息';
      case AppPermissionType.location:
        return '需要获取位置信息来提供基于地理位置的服务';
    }
  }
}

/// 权限请求结果
class PermissionRequestResult {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String? errorMessage;

  const PermissionRequestResult({
    required this.isGranted,
    this.isPermanentlyDenied = false,
    this.errorMessage,
  });

  /// 成功授权
  factory PermissionRequestResult.granted() =>
      const PermissionRequestResult(isGranted: true);

  /// 权限被拒绝
  factory PermissionRequestResult.denied([String? message]) =>
      PermissionRequestResult(isGranted: false, errorMessage: message);

  /// 权限被永久拒绝
  factory PermissionRequestResult.permanentlyDenied([String? message]) =>
      PermissionRequestResult(
        isGranted: false,
        isPermanentlyDenied: true,
        errorMessage: message,
      );
}

/// 权限管理服务
class PermissionService {
  /// 统一的权限检查和请求方法
  static Future<PermissionRequestResult> requestPermission(
    AppPermissionType permissionType, {
    BuildContext? context,
    bool showRationale = true,
  }) async {
    try {
      // 获取当前权限状态
      final permission = _getPermissionForType(permissionType);
      final status = await permission.status;

      debugPrint('🔒 检查权限: ${permissionType.displayName}, 当前状态: $status');

      // 如果已授权，直接返回成功
      if (status.isGranted) {
        return PermissionRequestResult.granted();
      }

      // 如果永久拒绝，提示用户去设置
      if (status.isPermanentlyDenied) {
        if (context != null) {
          await _showPermissionDeniedDialog(
            context,
            permissionType.displayName,
          );
        }
        return PermissionRequestResult.permanentlyDenied('权限被永久拒绝，请在设置中手动开启');
      }

      // 如果需要显示说明，先展示权限说明对话框
      if (showRationale && context != null && status.isDenied) {
        final shouldRequest = await showPermissionRationaleDialog(
          context,
          title: permissionType.displayName,
          content: permissionType.description,
        );
        if (!shouldRequest) {
          return PermissionRequestResult.denied('用户拒绝授权');
        }
      }

      // 请求权限
      final result = await permission.request();
      debugPrint('🔒 权限请求结果: ${permissionType.displayName} -> $result');

      if (result.isGranted) {
        return PermissionRequestResult.granted();
      } else if (result.isPermanentlyDenied) {
        if (context != null) {
          await _showPermissionDeniedDialog(
            context,
            permissionType.displayName,
          );
        }
        return PermissionRequestResult.permanentlyDenied('权限被永久拒绝');
      } else {
        return PermissionRequestResult.denied('权限被拒绝');
      }
    } catch (e) {
      debugPrint('🔒 权限请求异常: $e');
      return PermissionRequestResult.denied('权限请求异常: $e');
    }
  }

  /// 检查权限状态（不请求）
  static Future<bool> checkPermission(AppPermissionType permissionType) async {
    try {
      final permission = _getPermissionForType(permissionType);
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('🔒 检查权限异常: $e');
      return false;
    }
  }

  /// 获取特定类型的权限
  static Permission _getPermissionForType(AppPermissionType permissionType) {
    switch (permissionType) {
      case AppPermissionType.photos:
        // Android 13+ 使用photos权限，iOS始终使用photos权限
        return Permission.photos;
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.storage:
        return Permission.storage;
      case AppPermissionType.notification:
        return Permission.notification;
      case AppPermissionType.location:
        return Permission.location;
    }
  }

  /// 请求相机和相册权限（用于拍照和选择图片）
  static Future<PermissionRequestResult> requestCameraAndPhotosPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    // 先请求相机权限
    final cameraResult = await requestPermission(
      AppPermissionType.camera,
      context: context,
      showRationale: showRationale,
    );

    if (!cameraResult.isGranted) {
      return cameraResult;
    }

    // 再请求照片权限
    final photosResult = await requestPermission(
      AppPermissionType.photos,
      context: context,
      showRationale: showRationale,
    );

    return photosResult;
  }

  /// 请求存储相关权限（兼容不同Android版本）
  static Future<PermissionRequestResult> requestStoragePermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    if (Platform.isAndroid) {
      // Android 13+ 使用photos权限
      if (await _isAndroid13OrHigher()) {
        return await requestPermission(
          AppPermissionType.photos,
          context: context,
          showRationale: showRationale,
        );
      } else {
        // Android 12及以下使用storage权限
        return await requestPermission(
          AppPermissionType.storage,
          context: context,
          showRationale: showRationale,
        );
      }
    } else if (Platform.isIOS) {
      // iOS使用photos权限
      return await requestPermission(
        AppPermissionType.photos,
        context: context,
        showRationale: showRationale,
      );
    }

    return PermissionRequestResult.denied('不支持的平台');
  }

  /// 检查并请求存储权限（兼容旧方法）
  static Future<bool> checkAndRequestStoragePermission(
    BuildContext context,
  ) async {
    if (Platform.isAndroid) {
      // Android 13+ 使用新的照片权限
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          final result = await Permission.photos.request();
          return result.isGranted;
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog(context, '照片权限');
          return false;
        }
      } else {
        // Android 12 及以下使用存储权限
        final status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog(context, '存储权限');
          return false;
        }
      }
    } else if (Platform.isIOS) {
      // iOS 使用照片权限
      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        await _showPermissionDeniedDialog(context, '照片权限');
        return false;
      }
    }

    return false;
  }

  /// 检查是否为Android 13或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  /// 显示权限被拒绝的对话框
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
  ) async {
    if (!context.mounted) return;

    // 检查主题模式
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              '权限被拒绝',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '需要$permissionName才能保存文件。请在设置中手动开启权限。',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 显示权限申请说明对话框
  static Future<bool> showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '授予权限',
    String cancelText = '取消',
  }) async {
    if (!context.mounted) return false;

    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示保存进度对话框
  static void showSaveProgressDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示成功消息
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('成功'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误消息
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('错误'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
