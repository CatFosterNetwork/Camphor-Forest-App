// lib/pages/settings/options_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/constants/route_constants.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      useBackground: true, // 启用背景，与主题保持一致
      pageType: PageType.settings,
      forceStatusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(
        title: '选项',
      ),
      body: Column(
        children: [
          // 设置选项卡片
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: isDarkMode 
                  ? Colors.grey.shade800 
                  : Colors.white,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在下载...'),
            ],
          ),
        ),
      );

      // 模拟下载配置
      await Future.delayed(const Duration(seconds: 2));
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('下载成功'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在上传...'),
            ],
          ),
        ),
      );

      // 模拟上传配置
      await Future.delayed(const Duration(seconds: 2));
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('上传成功'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout(context, ref);
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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