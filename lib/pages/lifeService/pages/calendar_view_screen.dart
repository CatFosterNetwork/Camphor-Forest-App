// lib/pages/lifeService/pages/calendar_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:camphor_forest/core/services/toast_service.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';
import '../../../core/services/permission_service.dart';

/// 校历查看页面
class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  static const String calendarUrl =
      'https://data.swu.social/service/2025cal.webp';
  bool _isLoading = false;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      pageType: PageType.other,
      useBackground: false,
      appBar: ThemeAwareAppBar(
        title: '校历查询',
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _isLoading ? null : _saveCalendar,
            tooltip: '保存到相册',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            tooltip: '重置缩放',
          ),
        ],
      ),
      body: Container(
        color: isDarkMode ? Colors.black : Colors.white,
        child: Stack(
          children: [
            // 校历图片 - 使用InteractiveViewer实现缩放功能
            Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: GestureDetector(
                  onLongPress: _saveCalendar,
                  child: CachedNetworkImage(
                    imageUrl: calendarUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: isDarkMode ? Colors.white : Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载校历中...',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '加载失败',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '请检查网络连接后重试',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 长按保存提示
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        '正在保存...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // 使用提示
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '双指缩放查看 • 长按保存到相册',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存校历到相册
  Future<void> _saveCalendar() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 显示保存进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSaveProgressDialog(),
      );

      // 2. 请求权限
      final result = await PermissionService.requestStoragePermission(
        context: context,
        showRationale: true,
      );

      if (!result.isGranted) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showErrorSnackBar(
            context,
            result.errorMessage ?? '需要存储权限才能保存校历图片到相册',
          );
        }
        return;
      }

      // 3. 下载图片
      final Uint8List imageBytes = await _downloadImage(calendarUrl);

      // 4. 保存到相册
      await _saveImageToGallery(imageBytes);

      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        PermissionService.showSuccessSnackBar(context, '校历已成功保存到相册');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        PermissionService.showErrorSnackBar(context, '保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 下载图片
  Future<Uint8List> _downloadImage(String url) async {
    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery(Uint8List imageBytes) async {
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final fileName = 'calendar_${DateTime.now().millisecondsSinceEpoch}.webp';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    // 使用gal保存到相册
    await Gal.putImage(file.path);

    // 删除临时文件
    await file.delete();
  }

  /// 构建保存进度对话框
  Widget _buildSaveProgressDialog() {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            '正在保存校历...',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}
