// lib/core/services/permission_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 权限管理服务
class PermissionService {
  /// 检查并请求存储权限
  static Future<bool> checkAndRequestStoragePermission(BuildContext context) async {
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
  static Future<void> _showPermissionDeniedDialog(BuildContext context, String permissionName) async {
    if (!context.mounted) return;
    
    // 检查主题模式
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 24,
            ),
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
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示成功消息
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示错误消息
  static void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
