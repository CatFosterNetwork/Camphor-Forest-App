// lib/pages/settings/forest_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';

class ForestSettingsPage extends ConsumerWidget {
  const ForestSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false, // 设置页面使用纯色背景，保持专业感
      appBar: ThemeAwareAppBar(title: '森林功能设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '功能开关',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择要在主页显示的功能',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 使用说明
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 启用的功能会显示在主页的"树林隐藏"区域\n'
                    '• 点击功能图标可以快速跳转到对应页面\n'
                    '• 如果没有启用任何功能，整个区域将不会显示\n'
                    '• 功能布局采用4列网格显示',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
