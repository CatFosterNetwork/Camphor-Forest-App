// lib/pages/settings/options_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/config/providers/unified_config_service_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/widgets/theme_aware_dialog.dart';
import '../../core/constants/route_constants.dart';

/// 刷新所有配置相关的 Provider
void _refreshAllConfigProviders(WidgetRef ref) {
  ref.invalidate(configInitializationProvider);
  ref.invalidate(themeConfigNotifierProvider);
  ref.invalidate(selectedThemeCodeNotifierProvider);
  ref.invalidate(customThemeManagerProvider);
}

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      useBackground: false, // 设置页面使用纯色背景，保持专业感
      pageType: PageType.settings,
      // forceStatusBarIconBrightness: isDarkMode
      //     ? Brightness.light
      //     : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(title: '选项'),
      body: Column(
        children: [
          // 设置选项卡片
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSettingItem(
                      context,
                      ref,
                      '主页设置',
                      Icons.home_outlined,
                      RouteConstants.optionsIndexSettings,
                      isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      context,
                      ref,
                      '主题设置',
                      Icons.palette_outlined,
                      RouteConstants.optionsThemeSettings,
                      isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      context,
                      ref,
                      '个人资料设置',
                      Icons.person_outline,
                      RouteConstants.optionsProfileSettings,
                      isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      context,
                      ref,
                      '其他设置',
                      Icons.settings_outlined,
                      RouteConstants.optionsOtherSettings,
                      isDarkMode,
                    ),
                    _buildDivider(isDarkMode),
                    _buildSettingItem(
                      context,
                      ref,
                      '关于',
                      Icons.info_outline,
                      RouteConstants.optionsAbout,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 填充空间，让按钮区域位于底部
          const Spacer(),

          // 同步配置区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 下载云端配置
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _downloadConfig(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.blue.withAlpha(204)
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '下载云端配置到本地',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // 上传本地配置
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _uploadConfig(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.green.withAlpha(204)
                          : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '上传本地配置至云端',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 退出登录
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.red.withAlpha(230)
                      : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  '退出登录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    String route,
    bool isDarkMode,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : Colors.black87,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: isDarkMode ? Colors.white70 : Colors.black87,
        size: 16,
      ),
      onTap: () => context.push(route),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 1,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }

  Future<void> _downloadConfig(BuildContext context, WidgetRef ref) async {
    try {
      // 检查本地配置是否已修改
      final service = await ref.read(unifiedConfigServiceProvider.future);
      final hasChanges = await service.hasLocalConfigChanges();

      if (hasChanges) {
        // 如果本地配置已修改，显示确认对话框
        final result = await ThemeAwareDialog.showConfirmDialog(
          context,
          title: '覆盖本地配置？',
          message: '检测到本地配置已被修改。\n下载服务器配置将覆盖您的本地配置，是否继续？',
          positiveText: '继续下载',
          negativeText: '取消',
        );

        if (!result) {
          return; // 用户取消
        }
      }

      if (!context.mounted) return;

      // 显示加载对话框
      final isDarkMode = ref.read(effectiveIsDarkModeProvider);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Platform.isIOS
            ? CupertinoAlertDialog(
                content: const Row(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 16),
                    Text('正在从服务器下载配置...'),
                  ],
                ),
              )
            : AlertDialog(
                backgroundColor: isDarkMode
                    ? const Color(0xFF202125)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '正在从服务器下载配置...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );

      // 从服务器下载配置
      final result = await service.syncFromServer();

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置下载成功'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          debugPrint('OptionsScreen: 配置下载成功，刷新所有配置 Provider');
          _refreshAllConfigProviders(ref);
          debugPrint('OptionsScreen: 所有配置 Provider 刷新完成');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('配置下载失败: ${result.message}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadConfig(BuildContext context, WidgetRef ref) async {
    try {
      // 显示加载对话框
      final isDarkMode = ref.read(effectiveIsDarkModeProvider);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Platform.isIOS
            ? CupertinoAlertDialog(
                content: const Row(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 16),
                    Text('正在上传配置到服务器...'),
                  ],
                ),
              )
            : AlertDialog(
                backgroundColor: isDarkMode
                    ? const Color(0xFF202125)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '正在上传配置到服务器...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );

      // 上传配置到服务器
      final service = await ref.read(unifiedConfigServiceProvider.future);
      final success = await service.syncToServer();

      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置上传成功'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('配置上传失败，请稍后重试'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final result = await ThemeAwareDialog.showConfirmDialog(
      context,
      title: '提示',
      message: '确定退出登录吗？',
      positiveText: '确定',
      negativeText: '取消',
    );

    if (result) {
      await _logout(context, ref);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // 执行登出逻辑
    await ref.logout();

    // 导航到登录页面
    if (context.mounted) {
      context.go(RouteConstants.login);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已退出登录'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
