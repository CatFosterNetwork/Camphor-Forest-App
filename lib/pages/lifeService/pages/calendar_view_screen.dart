// lib/pages/lifeService/pages/calendar_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

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

    // 1. 请求权限
    final result = await PermissionService.requestStoragePermission(
      context: context,
      showRationale: true,
    );
    if (!result.isGranted) {
      FlutterPlatformAlert.showAlert(
        windowTitle: '权限错误',
        text: result.errorMessage ?? '需要存储权限才能保存校历图片',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.none,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 2. 显示加载指示器
    PermissionService.showSaveProgressDialog(context, '正在保存校历...');

    String? successMessage;
    String? errorMessage;

    try {
      // 3. 下载图片
      final response = await http.get(Uri.parse(calendarUrl));
      if (response.statusCode != 200) {
        throw Exception('下载图片失败 (状态码: ${response.statusCode})');
      }
      final Uint8List bytes = response.bodyBytes;

      // 4. 使用 gal 保存到相册
      await Gal.putImageBytes(bytes);
      successMessage = '校历已成功保存到相册';
    } catch (e) {
      errorMessage = '保存失败: $e';
    } finally {
      if (mounted) {
        // 5. 首先关闭对话框
        Navigator.of(context).pop();

        // 6. 然后根据结果显示原生提示
        if (successMessage != null) {
          FlutterPlatformAlert.showAlert(
            windowTitle: '成功',
            text: successMessage,
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.none,
          );
        }
        if (errorMessage != null) {
          FlutterPlatformAlert.showAlert(
            windowTitle: '错误',
            text: errorMessage,
            alertStyle: AlertButtonStyle.ok,
            iconStyle: IconStyle.none,
          );
        }

        // 7. 恢复状态
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
