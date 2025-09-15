// lib/pages/bbs/bbs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';

/// BBS (情绪树洞) 主页面
class BBSScreen extends ConsumerWidget {
  const BBSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: true,
      appBar: ThemeAwareAppBar(title: '情绪树洞'),
      body: _buildUnderConstructionContent(isDarkMode),
    );
  }

  Widget _buildUnderConstructionContent(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withAlpha(51),
                  Colors.blue.withAlpha(51),
                  Colors.purple.withAlpha(51),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.white.withAlpha(26)
                      : Colors.black.withAlpha(26),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 60,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 32),

          // 标题
          Text(
            '情绪树洞',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // 副标题
          Text(
            '一个倾听心声的温暖角落',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 48),

          // 建设中卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(230),
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
                    ],
            ),
            child: Column(
              children: [
                // 建设图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withAlpha(51),
                  ),
                  child: Icon(
                    Icons.construction,
                    size: 40,
                    color: Colors.orange.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // 建设中文字
                Text(
                  '正在建设中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '我们正在精心打造这个温暖的情绪分享空间\n请耐心等待，即将与您见面',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
