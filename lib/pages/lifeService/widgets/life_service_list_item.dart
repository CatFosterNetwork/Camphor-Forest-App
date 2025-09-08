// lib/pages/lifeService/widgets/life_service_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../models/life_service_item.dart';

/// 生活服务列表项组件
class LifeServiceListItem extends ConsumerWidget {
  final LifeServiceItem item;
  final bool isFirst;
  final bool isLast;

  const LifeServiceListItem({
    super.key,
    required this.item,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(isDarkMode ? 38 : 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: isDarkMode ? themeColor.withAlpha(204) : themeColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 20),

              // 文本内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // 箭头图标
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.white54 : Colors.black38,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
