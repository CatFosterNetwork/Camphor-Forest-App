// lib/pages/settings/other_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
// import 'package:device_info_plus/device_info_plus.dart'; // 暂时不使用

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';

class OtherSettingsPage extends ConsumerStatefulWidget {
  const OtherSettingsPage({super.key});

  @override
  ConsumerState<OtherSettingsPage> createState() => _OtherSettingsPageState();
}

class _OtherSettingsPageState extends ConsumerState<OtherSettingsPage> {
  String _cacheSize = '计算中...';
  bool _isCalculatingCache = true;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  /// 计算缓存大小
  Future<void> _calculateCacheSize() async {
    try {
      setState(() {
        _isCalculatingCache = true;
        _cacheSize = '计算中...';
      });

      final totalSize = await _getTotalCacheSize();

      setState(() {
        _cacheSize = _formatBytes(totalSize);
        _isCalculatingCache = false;
      });
    } catch (e) {
      setState(() {
        _cacheSize = '计算失败';
        _isCalculatingCache = false;
      });
    }
  }

  /// 获取总缓存大小
  Future<int> _getTotalCacheSize() async {
    int totalSize = 0;

    try {
      // 获取应用缓存目录
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        totalSize += await _getDirectorySize(cacheDir);
      }

      // 获取应用文档目录中的缓存
      final appDocDir = await getApplicationDocumentsDirectory();
      final appCacheDir = Directory('${appDocDir.path}/cache');
      if (await appCacheDir.exists()) {
        totalSize += await _getDirectorySize(appCacheDir);
      }

      // 获取应用支持目录中的缓存
      final appSupportDir = await getApplicationSupportDirectory();
      final supportCacheDir = Directory('${appSupportDir.path}/cache');
      if (await supportCacheDir.exists()) {
        totalSize += await _getDirectorySize(supportCacheDir);
      }
    } catch (e) {
      // 如果获取失败，返回0
      totalSize = 0;
    }

    return totalSize;
  }

  /// 计算目录大小
  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          size += stat.size;
        }
      }
    } catch (e) {
      // 忽略无法访问的文件
    }
    return size;
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;
    final activeColor = isDarkMode ? themeColor.withAlpha(204) : themeColor;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false, // 设置页面使用纯色背景，保持专业感
      forceStatusBarIconBrightness: isDarkMode
          ? Brightness.light
          : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(title: '其他设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 功能设置
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '功能设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: Text(
                      '推送通知',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '接收应用推送消息',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现推送通知开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),

                  SwitchListTile(
                    title: Text(
                      '课程提醒',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '上课前10分钟提醒',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现课程提醒开关
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                ],
              ),
            ),
          ),

          // 缓存设置
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '缓存设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: Icon(
                      Icons.storage_outlined,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '缓存大小',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (_isCalculatingCache) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: Platform.isIOS
                                ? CupertinoActivityIndicator(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  )
                                : CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _cacheSize,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showClearCacheDialog(context, isDarkMode),
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('清理缓存'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.orange.withAlpha(204)
                            : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 网络设置
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '网络设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: Text(
                      '仅WiFi下载',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '节省移动数据流量',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: true,
                    onChanged: (value) {
                      // TODO: 实现WiFi下载限制
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.network_check,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '网络诊断',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '检查网络连接状态',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 16,
                    ),
                    onTap: () =>
                        _showNetworkDiagnostic(context, isDarkMode, themeColor),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // 语言和地区
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '语言',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '语言',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '简体中文',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      size: 16,
                    ),
                    onTap: () => _showLanguageSelector(context, isDarkMode),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // 实验性功能
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode
                  ? Border.all(color: Colors.white.withAlpha(26), width: 1)
                  : null,
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '实验性功能',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.science_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这些功能仍在开发中，可能不稳定',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: Text(
                      '灵动岛',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '动态显示重要信息',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: 实现灵动岛功能
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),

                  SwitchListTile(
                    title: Text(
                      '自动续期自动签到',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '开启后每日进入应用将自动续期开放数智西大自动签到',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: false,
                    onChanged: (value) {
                      // TODO: 实现自动续期签到服务
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: activeColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isDarkMode) async {
    final result = await FlutterPlatformAlert.showCustomAlert(
      windowTitle: '清理缓存',
      text: '确定要清理所有缓存数据吗？这将清除临时文件和图片缓存。',
      positiveButtonTitle: '确定',
      negativeButtonTitle: '取消',
    );

    if (result == CustomButton.positiveButton) {
      _performCacheClear(context, isDarkMode);
    }
  }

  /// 执行真实的缓存清理
  Future<void> _performCacheClear(BuildContext context, bool isDarkMode) async {
    // 显示清理进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CacheClearProgressDialog(isDarkMode: isDarkMode),
    );

    try {
      // 执行真实的缓存清理
      final result = await _clearAllCache();

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框

        // 重新计算缓存大小
        _calculateCacheSize();

        // 显示结果
        FlutterPlatformAlert.showAlert(
          windowTitle: '清理完成',
          text: '缓存清理完成！释放了 ${_formatBytes(result.clearedSize)}',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.none,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框

        FlutterPlatformAlert.showAlert(
          windowTitle: '清理失败',
          text: '缓存清理失败: $e',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.none,
        );
      }
    }
  }

  /// 清理所有缓存
  Future<CacheClearResult> _clearAllCache() async {
    int totalClearedSize = 0;
    int totalFiles = 0;

    try {
      // 清理临时目录
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final result = await _clearDirectory(tempDir);
        totalClearedSize += result.size;
        totalFiles += result.files;
      }

      // 清理应用文档目录中的缓存
      final appDocDir = await getApplicationDocumentsDirectory();
      final appCacheDir = Directory('${appDocDir.path}/cache');
      if (await appCacheDir.exists()) {
        final result = await _clearDirectory(appCacheDir);
        totalClearedSize += result.size;
        totalFiles += result.files;
      }

      // 清理应用支持目录中的缓存
      final appSupportDir = await getApplicationSupportDirectory();
      final supportCacheDir = Directory('${appSupportDir.path}/cache');
      if (await supportCacheDir.exists()) {
        final result = await _clearDirectory(supportCacheDir);
        totalClearedSize += result.size;
        totalFiles += result.files;
      }

      return CacheClearResult(
        clearedSize: totalClearedSize,
        clearedFiles: totalFiles,
        success: true,
      );
    } catch (e) {
      return CacheClearResult(
        clearedSize: totalClearedSize,
        clearedFiles: totalFiles,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 清理指定目录
  Future<DirectoryClearResult> _clearDirectory(Directory directory) async {
    int clearedSize = 0;
    int clearedFiles = 0;

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            await entity.delete();
            clearedSize += stat.size;
            clearedFiles++;
          } catch (e) {
            // 忽略无法删除的文件
          }
        }
      }
    } catch (e) {
      // 忽略目录访问错误
    }

    return DirectoryClearResult(size: clearedSize, files: clearedFiles);
  }

  void _showNetworkDiagnostic(
    BuildContext context,
    bool isDarkMode,
    Color themeColor,
  ) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => NetworkDiagnosticDialog(
          isDarkMode: isDarkMode,
          themeColor: themeColor,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => NetworkDiagnosticDialog(
          isDarkMode: isDarkMode,
          themeColor: themeColor,
        ),
      );
    }
  }

  void _showLanguageSelector(BuildContext context, bool isDarkMode) {
    if (Platform.isIOS) {
      _showIOSLanguageSelector(context);
    } else {
      _showAndroidLanguageSelector(context, isDarkMode);
    }
  }

  void _showIOSLanguageSelector(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          '选择语言',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: const Text(
          '当前语言：简体中文',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现语言切换逻辑
            },
            child: const Text(
              '简体中文',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现语言切换逻辑
            },
            child: const Text(
              'English',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ),
      ),
    );
  }

  void _showAndroidLanguageSelector(BuildContext context, bool isDarkMode) {
    final currentTheme = ref.read(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;
    final activeColor = isDarkMode ? themeColor.withAlpha(204) : themeColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        title: Text(
          '选择语言',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(
                '简体中文',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              value: 'zh_CN',
              groupValue: 'zh_CN',
              activeColor: activeColor,
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: Text(
                'English',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              value: 'en_US',
              groupValue: 'zh_CN',
              activeColor: activeColor,
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// 网络诊断结果数据类
class NetworkDiagnosticResult {
  final bool isConnected;
  final String connectionType;
  final bool serverReachable;
  final int? latency;
  final String? error;

  NetworkDiagnosticResult({
    required this.isConnected,
    required this.connectionType,
    required this.serverReachable,
    this.latency,
    this.error,
  });
}

/// 网络诊断对话框
class NetworkDiagnosticDialog extends StatefulWidget {
  final bool isDarkMode;
  final Color themeColor;

  const NetworkDiagnosticDialog({
    super.key,
    required this.isDarkMode,
    required this.themeColor,
  });

  @override
  State<NetworkDiagnosticDialog> createState() =>
      _NetworkDiagnosticDialogState();
}

class _NetworkDiagnosticDialogState extends State<NetworkDiagnosticDialog> {
  bool _isLoading = true;
  NetworkDiagnosticResult? _result;

  @override
  void initState() {
    super.initState();
    _performNetworkDiagnostic();
  }

  /// 执行网络诊断
  Future<void> _performNetworkDiagnostic() async {
    try {
      setState(() {
        _isLoading = true;
        _result = null;
      });

      // 检查网络连接
      final connectivity = await _checkConnectivity();

      // 检查服务器连接和延迟
      final serverTest = await _testServerConnection();

      setState(() {
        _result = NetworkDiagnosticResult(
          isConnected: connectivity['isConnected'] ?? false,
          connectionType: connectivity['type'] ?? '未知',
          serverReachable: serverTest['reachable'] ?? false,
          latency: serverTest['latency'],
          error: serverTest['error'],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = NetworkDiagnosticResult(
          isConnected: false,
          connectionType: '检测失败',
          serverReachable: false,
          error: e.toString(),
        );
        _isLoading = false;
      });
    }
  }

  /// 检查网络连接状态
  Future<Map<String, dynamic>> _checkConnectivity() async {
    try {
      // 尝试查看网络接口
      final interfaces = await NetworkInterface.list();
      bool hasActiveInterface = false;
      String connectionType = '未连接';

      for (final interface in interfaces) {
        if (interface.addresses.isNotEmpty) {
          hasActiveInterface = true;
          // 判断连接类型
          if (interface.name.toLowerCase().contains('wlan') ||
              interface.name.toLowerCase().contains('wifi')) {
            connectionType = 'WiFi';
          } else if (interface.name.toLowerCase().contains('cellular') ||
              interface.name.toLowerCase().contains('mobile')) {
            connectionType = '移动数据';
          } else if (interface.name.toLowerCase().contains('eth')) {
            connectionType = '以太网';
          } else {
            connectionType = '网络已连接';
          }
          break;
        }
      }

      return {'isConnected': hasActiveInterface, 'type': connectionType};
    } catch (e) {
      return {'isConnected': false, 'type': '检测失败', 'error': e.toString()};
    }
  }

  /// 测试服务器连接和延迟
  Future<Map<String, dynamic>> _testServerConnection() async {
    try {
      final stopwatch = Stopwatch()..start();

      // 测试百度（中国常用的网站）
      final response = await http
          .get(
            Uri.parse('https://www.baidu.com'),
            headers: {'User-Agent': 'Camphor Forest App'},
          )
          .timeout(const Duration(seconds: 10));

      stopwatch.stop();

      return {
        'reachable': response.statusCode == 200,
        'latency': stopwatch.elapsedMilliseconds,
      };
    } on TimeoutException {
      return {'reachable': false, 'error': '连接超时'};
    } on SocketException {
      return {'reachable': false, 'error': '网络不可达'};
    } catch (e) {
      return {'reachable': false, 'error': '连接失败: ${e.toString()}'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildDialogContent();
    
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: const Text(
          '网络诊断',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: content,
        ),
        actions: [
          if (_result != null && !_isLoading) ...[
            CupertinoDialogAction(
              onPressed: _performNetworkDiagnostic,
              child: const Text(
                '重新检测',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
          ],
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      );
    } else {
      return AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF202125)
            : Colors.white,
        title: Text(
          '网络诊断',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: content,
        ),
        actions: [
          if (_result != null && !_isLoading) ...[
            TextButton(
              onPressed: _performNetworkDiagnostic,
              child: Text(
                '重新检测',
                style: TextStyle(
                  color: widget.themeColor,
                ),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDialogContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧图标，固定宽度
                  SizedBox(
                    width: 24,
                    child: Icon(
                      Platform.isIOS ? CupertinoIcons.wifi : Icons.network_check,
                      size: 18,
                      color: Platform.isIOS 
                          ? (widget.isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6))
                          : (widget.isDarkMode ? Colors.white54 : Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 中间文本
                  Expanded(
                    child: Text(
                      '正在检查网络连接...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Platform.isIOS
                            ? (widget.isDarkMode ? Colors.white.withOpacity(0.85) : Colors.black87)
                            : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                  // 右侧指示器
                  Platform.isIOS
                      ? const CupertinoActivityIndicator()
                      : SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: widget.themeColor,
                          ),
                        ),
                ],
              ),
            ),
            if (!Platform.isIOS) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                color: widget.themeColor,
                backgroundColor: widget.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ],
          ],
        ),
      );
    }

    if (_result == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultItem(
            '网络连接',
            _result!.isConnected ? '已连接' : '未连接',
            _result!.isConnected,
            Platform.isIOS ? CupertinoIcons.wifi : Icons.wifi,
          ),
          _buildResultItem(
            '连接类型',
            _result!.connectionType,
            _result!.isConnected,
            Platform.isIOS ? CupertinoIcons.device_phone_portrait : Icons.router,
          ),
          _buildResultItem(
            '服务器连接',
            _result!.serverReachable ? '正常' : (_result!.error ?? '失败'),
            _result!.serverReachable,
            Platform.isIOS ? CupertinoIcons.cloud : Icons.cloud,
          ),
          if (_result!.latency != null)
            _buildResultItem(
              '延迟',
              '${_result!.latency}ms',
              _result!.latency! < 500,
              Platform.isIOS ? CupertinoIcons.speedometer : Icons.speed,
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, bool isGood, IconData icon) {
    Color statusColor;
    Color iconColor;
    
    if (Platform.isIOS) {
      statusColor = isGood 
          ? CupertinoColors.systemGreen 
          : CupertinoColors.destructiveRed;
      iconColor = widget.isDarkMode 
          ? Colors.white.withOpacity(0.6)
          : Colors.black.withOpacity(0.6);
    } else {
      if (isGood) {
        statusColor = widget.isDarkMode
            ? Colors.green.shade300
            : Colors.green.shade700;
      } else {
        statusColor = widget.isDarkMode
            ? Colors.red.shade300
            : Colors.red.shade700;
      }
      iconColor = widget.isDarkMode ? Colors.white54 : Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧图标，固定宽度
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          // 标签文字，左对齐
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Platform.isIOS
                  ? (widget.isDarkMode ? Colors.white.withOpacity(0.85) : Colors.black87)
                  : (widget.isDarkMode ? Colors.white70 : Colors.black87),
              fontWeight: Platform.isIOS ? FontWeight.w500 : FontWeight.w500,
            ),
          ),
          // 弹性空间
          const Spacer(),
          // 右侧状态值
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: statusColor, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 缓存清理结果数据类
class CacheClearResult {
  final int clearedSize;
  final int clearedFiles;
  final bool success;
  final String? error;

  CacheClearResult({
    required this.clearedSize,
    required this.clearedFiles,
    required this.success,
    this.error,
  });
}

/// 目录清理结果数据类
class DirectoryClearResult {
  final int size;
  final int files;

  DirectoryClearResult({required this.size, required this.files});
}

/// 缓存清理进度对话框
class CacheClearProgressDialog extends StatefulWidget {
  final bool isDarkMode;

  const CacheClearProgressDialog({super.key, required this.isDarkMode});

  @override
  State<CacheClearProgressDialog> createState() =>
      _CacheClearProgressDialogState();
}

class _CacheClearProgressDialogState extends State<CacheClearProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _steps = [
    '正在清理临时文件...',
    '正在清理图片缓存...',
    '正在清理网络缓存...',
    '正在整理存储空间...',
    '清理完成！',
  ];

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _startStepAnimation();
  }

  void _startStepAnimation() {
    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted && _currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 清理图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.cleaning_services,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),

            // 标题
            Text(
              '正在清理缓存',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // 进度指示器
            LinearProgressIndicator(
              color: Colors.orange,
              backgroundColor: widget.isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),

            // 当前步骤
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_currentStep],
                key: ValueKey(_currentStep),
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // 提示文字
            Text(
              '请稍等，正在清理应用缓存...',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.white54 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

    return Platform.isIOS
        ? CupertinoAlertDialog(
            content: content,
          )
        : AlertDialog(
            backgroundColor: widget.isDarkMode
                ? const Color(0xFF202125)
                : Colors.white,
            content: content,
          );
  }
}
