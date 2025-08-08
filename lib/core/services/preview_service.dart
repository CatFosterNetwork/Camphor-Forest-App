// lib/core/services/preview_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
// photo_view dependency removed - using simple InteractiveViewer

/// 预览服务 - 用于显示和保存图片预览
class PreviewService {
  /// 显示预览模态框
  static Future<void> showPreviewModal(
    BuildContext context, {
    required String base64Image,
    required String title,
    required bool isDarkMode,
  }) async {
    // 解码base64图片
    final imageData = _decodeBase64Image(base64Image);
    if (imageData == null) {
      _showSnackBar(context, '图片数据无效', isError: true);
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // 图片预览区域
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.memory(
                          imageData,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.error,
                              size: 64,
                              color: isDarkMode ? Colors.white54 : Colors.black54,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 底部按钮
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _saveImageToGallery(context, imageData, title);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('保存到相册'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                          foregroundColor: isDarkMode ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 解码Base64图片
  static Uint8List? _decodeBase64Image(String base64String) {
    try {
      // 移除data:image前缀
      String base64Data = base64String;
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',').last;
      }
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('Base64解码失败: $e');
      return null;
    }
  }

  /// 保存图片到相册
  static Future<void> _saveImageToGallery(
    BuildContext context,
    Uint8List imageData,
    String title,
  ) async {
    try {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar(context, '需要存储权限才能保存图片', isError: true);
        return;
      }

      // 获取保存路径
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null || !directory.existsSync()) {
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        throw Exception('无法找到保存路径');
      }

      // 保存文件
      final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageData);

      _showSnackBar(context, '保存成功: $fileName');
    } catch (e) {
      _showSnackBar(context, '保存失败: $e', isError: true);
    }
  }

  /// 显示SnackBar
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
